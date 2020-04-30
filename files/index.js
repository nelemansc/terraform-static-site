'use strict';
exports.handler = (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;
    
    headers['strict-transport-security'] = [{
        key:   'Strict-Transport-Security', 
        value: "max-age=31536000; includeSubdomains; preload"
    }];

    headers['content-security-policy'] = [{
        key:   'Content-Security-Policy',
        value: "default-src 'none'; font-src 'self'; img-src 'self' data: https:; script-src 'self' 'sha256-ZUBnUDfsX/mhVi0F0de6Opxnc1S4t7vaSqZs0/XW+R0=' 'sha256-AcZHBRd1XuxlEnarbX/geO9CkqhjUcvk6yLPqe+p2Nw=' 'sha256-0HI3nX1RARjFCqzL9ivUeKOYwI+pzT3ArGHEWpZvntE='; style-src 'self' 'unsafe-inline'; object-src 'self' data: blob:; frame-src 'self'"
    }];

    headers['feature-policy'] = [{
        key:   'Feature-Policy',
        value: "geolocation 'none'; "
    }];
	
    headers['x-content-type-options'] = [{
        key:   'X-Content-Type-Options',
        value: "nosniff"
    }];
    
    headers['x-frame-options'] = [{
        key:   'X-Frame-Options',
        value: "DENY"
    }];
    
    headers['x-xss-protection'] = [{
        key:   'X-XSS-Protection',
        value: "1; mode=block"
    }];

    headers['referrer-policy'] = [{
        key:   'Referrer-Policy',
        value: "same-origin"
    }];
    
    headers['x-powered-by'] = [{
        key:   'X-Powered-By',
        value: "coffee and craft brews"
    }];

    headers['server'] = [{
        key:   'Server',
        value: "starlink"
    }];
    
    callback(null, response);
};
