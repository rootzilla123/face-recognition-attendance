'use client';
import { useEffect, useState } from 'react';
import RouteGuard from '../components/RouteGuard';
import { getToken } from '@/lib/auth';

const API = typeof window !== 'undefined'
  ? `${window.location.protocol}//${window.location.hostname}:8001`
  : 'http://localhost:8001';

function PreferencesContent() {
  const [prefs, setPrefs] = useState({ sms: true, email: true, in_app: true, language: 'en' });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    fetch(`${API}/api/v1/notifications/preferences`, {
      headers: { Authorization: `Bearer ${getToken()}` }
    }).then(r => r.ok ? r.json() : null).then(d => { if (d?.preferences) setPrefs(d.preferences); }).catch(() => {});
  }, []);

  const save = async () => {
    setSaving(true); setSaved(false);
    await fetch(`${API}/api/v1/notifications/preferences`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${getToken()}` },
      body: JSON.stringify(prefs),
    });
    setSaving(false); setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  const Toggle = ({ label, desc, k }: { label: string; desc: string; k: keyof typeof prefs }) => (
    <div className="flex items-center justify-between py-4 border-b border-gray-50 last:border-0">
      <div>
        <p className="font-medium text-gray-900 text-sm">{label}</p>
        <p className="text-xs text-gray-400 mt-0.5">{desc}</p>
      </div>
      <button onClick={() => setPrefs(p => ({ ...p, [k]: !p[k as keyof typeof prefs] }))}
        className={`relative w-12 h-6 rounded-full transition-colors ${prefs[k as keyof typeof prefs] ? 'bg-blue-500' : 'bg-gray-200'}`}>
        <div className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow transition-transform ${prefs[k as keyof typeof prefs] ? 'translate-x-7' : 'translate-x-1'}`} />
      </button>
    </div>
  );

  return (
    <div className="p-8 space-y-6 max-w-lg">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Notification Preferences</h1>
        <p className="text-gray-500 mt-1">Choose how you want to be notified</p>
      </div>
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <Toggle label="In-App Notifications" desc="Receive alerts inside the app" k="in_app" />
        <Toggle label="Email Notifications" desc="Get notified via email" k="email" />
        <Toggle label="SMS Notifications" desc="Receive text messages on your phone" k="sms" />
        <div className="pt-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">Preferred Language</label>
          <select value={prefs.language} onChange={e => setPrefs(p => ({ ...p, language: e.target.value }))}
            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500">
            <option value="en">English</option>
            <option value="sw">Swahili</option>
            <option value="fr">French</option>
            <option value="ar">Arabic</option>
          </select>
        </div>
      </div>
      <button onClick={save} disabled={saving}
        className="px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition">
        {saving ? 'Saving...' : saved ? '✓ Saved' : 'Save Preferences'}
      </button>
    </div>
  );
}

export default function PreferencesPage() {
  return <RouteGuard allowedRoles={['parent']}><PreferencesContent /></RouteGuard>;
}
