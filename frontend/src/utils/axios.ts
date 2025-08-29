import axios from 'axios';

// Create axios instance
const api = axios.create({
  baseURL: 'http://localhost:5050',
  timeout: 10000,
});

// Request interceptor to add JWT token
api.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle errors
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      sessionStorage.removeItem('authToken');
      sessionStorage.removeItem('userData');
      window.location.href = '/';
    }
    return Promise.reject(error);
  }
);

export default api; 