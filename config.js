/**
 * LilyJoe Textiles ERP - Frontend Configuration
 * Resolves the backend API URL dynamically for Local, Railway, and Vercel environments.
 */
window.LILYJOE_CONFIG = {
    /**
     * Resolves the active API base URL.
     * 1. If an override is set in localStorage ('lilyjoe_api_url' or 'flowtive_api_url'), use it.
     * 2. If running on localhost or 127.0.0.1, use relative 'api' (for local XAMPP / PHP server).
     * 3. In production (e.g. Vercel), defaults to 'api' which Vercel proxies to Railway via vercel.json rewrites,
     *    or directly connects to Railway if configured.
     */
    getApiBase: function() {
        const customUrl = localStorage.getItem('lilyjoe_api_url') || localStorage.getItem('flowtive_api_url');
        if (customUrl) {
            return customUrl.replace(/\/+$/, '');
        }
        return 'api';
    },

    /**
     * Helper to configure the backend API URL at runtime from the browser console or settings.
     * Example: LILYJOE_CONFIG.setApiBase('https://lilyjoe-api.up.railway.app/api')
     */
    setApiBase: function(url) {
        if (!url || url.trim() === '') {
            localStorage.removeItem('lilyjoe_api_url');
            console.log('[Config] Reset API base to default relative "api"');
        } else {
            const clean = url.trim().replace(/\/+$/, '');
            localStorage.setItem('lilyjoe_api_url', clean);
            console.log('[Config] API base set to:', clean);
        }
    }
};
