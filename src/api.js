import axios from 'axios';

// Em produção usa API da Vercel, em desenvolvimento usa localhost
const API_BASE = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: API_BASE,
  timeout: 15000,
});

// Interceptor para adicionar token de auth
api.interceptors.request.use(config => {
  const token = localStorage.getItem('petshop_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Sessao vencida (ou token antigo, de antes das lojas separadas): limpa e
// volta para a tela de login.
api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401 && err.response?.data?.sessao) {
      try {
        localStorage.removeItem('petshop_token');
        localStorage.removeItem('petshop_user');
      } catch (_) { /* sem localStorage */ }
      window.location.reload();
    }
    return Promise.reject(err);
  }
);

export default api;
export { API_BASE };
