const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3001;

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type']
}));
app.use(express.json());
app.use(express.static(__dirname));

// Root route to serve HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'topology-viz.html'));
});

// Azure CLI를 통해 네트워크 경로 추적 실행
app.post('/api/trace-network', async (req, res) => {
    const { resourceGroup, vmName, sourceIP, destIP, destPort, protocol } = req.body;

    if (!resourceGroup || !vmName || !sourceIP || !destIP || !destPort || !protocol) {
        return res.status(400).json({ error: '모든 필드를 입력해주세요' });
    }

    // PowerShell 스크립트 실행
    const scriptPath = path.join(__dirname, 'get-full-network-path-v2.ps1');
    const command = `
        & "${scriptPath}" \
        -ResourceGroup "${resourceGroup}" \
        -VMName "${vmName}" \
        -SourceIP "${sourceIP}" \
        -DestIP "${destIP}" \
        -DestPort "${destPort}" \
        -Protocol "${protocol}"
    `;

    const ps = spawn('powershell.exe', ['-Command', command]);

    let output = '';
    let errorOutput = '';

    ps.stdout.on('data', (data) => {
        output += data.toString();
    });

    ps.stderr.on('data', (data) => {
        errorOutput += data.toString();
    });

    ps.on('close', (code) => {
        if (code !== 0) {
            console.error('PowerShell Error:', errorOutput);
            return res.status(500).json({ error: '스크립트 실행 실패', details: errorOutput });
        }

        // JSON 출력 추출
        try {
            const jsonMatch = output.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                const data = JSON.parse(jsonMatch[0]);
                res.json(data);
            } else {
                res.status(500).json({ error: 'JSON 파싱 실패', output });
            }
        } catch (e) {
            res.status(500).json({ error: 'JSON 파싱 에러', details: e.message });
        }
    });
});

// Azure 로그아웃
app.post('/api/azure-logout', (req, res) => {
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);

    execAsync('az logout')
        .then(() => {
            res.json({ success: true, message: '로그아웃 완료' });
        })
        .catch((err) => {
            res.status(500).json({ success: false, error: err.message });
        });
});

// Azure 로그인 상태 확인
app.get('/api/azure-status', (req, res) => {
    const ps = spawn('powershell.exe', ['az', 'account', 'show', '--output', 'json']);

    let output = '';
    ps.stdout.on('data', (data) => {
        output += data.toString();
    });

    ps.on('close', (code) => {
        if (code === 0) {
            try {
                const account = JSON.parse(output);
                res.json({
                    authenticated: true,
                    user: account.user.name,
                    subscription: account.name
                });
            } catch (e) {
                res.json({ authenticated: false });
            }
        } else {
            res.json({ authenticated: false });
        }
    });
});

// Azure 로그인 - Device Code를 반환 (사용자가 브라우저에서 입력)
app.post('/api/azure-login', async (req, res) => {
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);

    try {
        // Device code 가져오기 (timeout 설정)
        const { stdout, stderr } = await Promise.race([
            execAsync('az login --use-device-code --output json 2>&1'),
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Timeout')), 5000)
            )
        ]);

        // 출력에서 device code와 URL 추출
        const match = stdout.match(/To sign in, use a web browser to open the page (https:\/\/microsoft\.com\/devicelogin) and enter the code ([A-Z0-9]+)/);

        if (match) {
            res.json({
                success: true,
                loginUrl: match[1],
                deviceCode: match[2],
                message: '브라우저에서 로그인하세요'
            });
        } else {
            // 이미 로그인된 상태
            res.json({
                success: true,
                message: '이미 Azure에 로그인되어 있습니다',
                authenticated: true
            });
        }
    } catch (error) {
        console.error('Login error:', error.message);
        // Timeout이거나 이미 로그인된 상태
        res.json({
            success: true,
            message: '이미 Azure에 로그인되어 있습니다',
            authenticated: true
        });
    }
});

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
