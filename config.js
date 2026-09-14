/**
 * LilyJoe Textiles ERP - Frontend Configuration
 * Resolves the backend API URL dynamically for Local, Railway, and Vercel environments.
 */
window.LILYJOE_CONFIG = {
    // Live production Railway backend API
    PRODUCTION_API: 'https://lilyjoe-textiles-production.up.railway.app/api',

    /**
     * Resolves the active API base URL.
     * 1. If an override is set in localStorage ('lilyjoe_api_url' or 'flowtive_api_url'), use it.
     * 2. If running locally (localhost / 127.0.0.1 / file://) on XAMPP, use relative 'api'.
     * 3. In cloud production (e.g. Vercel), directly use the live Railway backend API.
     */
    getApiBase: function() {
        const customUrl = localStorage.getItem('lilyjoe_api_url') || localStorage.getItem('flowtive_api_url');
        if (customUrl && customUrl !== 'api' && customUrl !== '/api') {
            return customUrl.replace(/\/+$/, '');
        }

        // Detect local environment (XAMPP / local Apache)
        const hostname = (window.location && window.location.hostname) ? window.location.hostname : '';
        if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '') {
            return 'api';
        }

        // Production environment (Vercel) directly calls Railway backend
        return this.PRODUCTION_API;
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
