// install_prompt.js – Handles PWA install prompt
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent the mini-infobar from appearing on mobile
    e.preventDefault();
    // Stash the event so it can be triggered later.
    deferredPrompt = e;
    // Optionally, update UI to notify the user they can install.
    const installBtn = document.createElement('button');
    installBtn.innerText = '앱 설치';
    installBtn.style.position = 'fixed';
    installBtn.style.bottom = '20px';
    installBtn.style.right = '20px';
    installBtn.style.padding = '10px 15px';
    installBtn.style.background = '#667EEA';
    installBtn.style.color = '#fff';
    installBtn.style.border = 'none';
    installBtn.style.borderRadius = '5px';
    installBtn.style.boxShadow = '0 2px 6px rgba(0,0,0,0.2)';
    installBtn.style.zIndex = '1000';
    installBtn.addEventListener('click', async () => {
        if (deferredPrompt) {
            deferredPrompt.prompt();
            const { outcome } = await deferredPrompt.userChoice;
            console.log('User response to the install prompt:', outcome);
            deferredPrompt = null;
            installBtn.remove();
        }
    });
    document.body.appendChild(installBtn);
});
