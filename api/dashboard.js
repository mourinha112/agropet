import { createClient } from '@supabase/supabase-js';
import { montarDashboard, dashboardVazio } from './_lib/dashboard.js';

const supabaseUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_ANON_KEY;

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(200).json(dashboardVazio());

  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    return res.status(200).json(await montarDashboard(supabase));
  } catch (err) {
    console.error('Dashboard error:', err);
    return res.status(200).json(dashboardVazio());
  }
}
