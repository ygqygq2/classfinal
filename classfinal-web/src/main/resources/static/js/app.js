let uploadedFileId = null;
let uploadedFilename = null;
let encryptedFileId = null;
let encryptedFilename = null;

// 上传区域交互
const uploadArea = document.getElementById('uploadArea');
const fileInput = document.getElementById('fileInput');
const fileInfo = document.getElementById('fileInfo');

uploadArea.addEventListener('click', () => fileInput.click());

uploadArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    uploadArea.classList.add('dragover');
});

uploadArea.addEventListener('dragleave', () => {
    uploadArea.classList.remove('dragover');
});

uploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadArea.classList.remove('dragover');
    if (e.dataTransfer.files.length) {
        fileInput.files = e.dataTransfer.files;
        handleFileUpload();
    }
});

fileInput.addEventListener('change', handleFileUpload);

// 处理文件上传
function handleFileUpload() {
    const file = fileInput.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    fetch('/api/upload', {
        method: 'POST',
        body: formData
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            uploadedFileId = data.fileId;
            uploadedFilename = data.filename;
            document.getElementById('fileName').textContent = data.filename;
            document.getElementById('fileSize').textContent = data.size;
            fileInfo.classList.add('show');
            document.getElementById('nextToStep2').disabled = false;
        } else {
            alert('上传失败: ' + data.message);
        }
    })
    .catch(err => {
        alert('上传失败: ' + err.message);
    });
}

// 无密码模式切换
document.getElementById('nopwd').addEventListener('change', function() {
    document.getElementById('passwordGroup').style.display = this.checked ? 'none' : 'block';
    document.getElementById('password').required = !this.checked;
});

// 步骤导航
document.getElementById('nextToStep2').addEventListener('click', () => showStep(2));
document.getElementById('backToStep1').addEventListener('click', () => showStep(1));
document.getElementById('nextToStep3').addEventListener('click', () => {
    if (validateStep2()) {
        updateConfirmation();
        showStep(3);
    }
});
document.getElementById('backToStep2').addEventListener('click', () => showStep(2));
document.getElementById('restart').addEventListener('click', () => {
    location.reload();
});

function showStep(step) {
    document.querySelectorAll('.step').forEach(el => el.classList.remove('active'));
    document.getElementById('step' + step).classList.add('active');
}

function validateStep2() {
    const packages = document.getElementById('packages').value.trim();
    const nopwd = document.getElementById('nopwd').checked;
    const password = document.getElementById('password').value.trim();
    const errorMsg = document.getElementById('errorMsg');

    errorMsg.innerHTML = '';

    if (!packages) {
        errorMsg.innerHTML = '<div class="alert alert-error">请输入要加密的包名</div>';
        return false;
    }

    if (!nopwd && !password) {
        errorMsg.innerHTML = '<div class="alert alert-error">请输入加密密码或选择无密码模式</div>';
        return false;
    }

    return true;
}

function updateConfirmation() {
    document.getElementById('confirmFilename').textContent = uploadedFilename;
    document.getElementById('confirmPackages').textContent = document.getElementById('packages').value;
    document.getElementById('confirmMode').textContent = document.getElementById('nopwd').checked ? '无密码模式' : '密码模式';
    document.getElementById('confirmExclude').textContent = document.getElementById('exclude').value || '无';
    document.getElementById('confirmLibjars').textContent = document.getElementById('libjars').checked ? '是' : '否';
}

// 开始加密
document.getElementById('startEncrypt').addEventListener('click', () => {
    document.getElementById('loading').classList.add('show');
    document.getElementById('startEncrypt').disabled = true;
    document.getElementById('backToStep2').disabled = true;

    const params = {
        fileId: uploadedFileId,
        filename: uploadedFilename,
        packages: document.getElementById('packages').value,
        password: document.getElementById('password').value,
        exclude: document.getElementById('exclude').value,
        libjars: document.getElementById('libjars').checked,
        nopwd: document.getElementById('nopwd').checked
    };

    fetch('/api/encrypt', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(params)
    })
    .then(res => res.json())
    .then(data => {
        document.getElementById('loading').classList.remove('show');
        document.getElementById('startEncrypt').disabled = false;
        document.getElementById('backToStep2').disabled = false;

        if (data.success) {
            encryptedFileId = data.encryptedFileId;
            encryptedFilename = data.encryptedFilename;
            document.getElementById('encryptedFilename').textContent = data.encryptedFilename;
            document.getElementById('encryptedSize').textContent = data.size;
            showStep(4);
        } else {
            alert('加密失败: ' + data.message);
        }
    })
    .catch(err => {
        document.getElementById('loading').classList.remove('show');
        document.getElementById('startEncrypt').disabled = false;
        document.getElementById('backToStep2').disabled = false;
        alert('加密失败: ' + err.message);
    });
});

// 下载
document.getElementById('downloadBtn').addEventListener('click', () => {
    window.location.href = `/api/download/${encryptedFileId}/${encryptedFilename}`;
});
