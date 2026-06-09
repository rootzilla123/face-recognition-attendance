import { pb } from './pocketbase';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8001';

export interface AuthUser {
  user_id: string;
  full_name: string;
  email: string;
  role: string;
  access_token: string;
  token_type: string;
}

export interface Student {
  id: string;
  student_id: string;
  full_name: string;
  grade_level: string;
  section?: string;
  parent_phone: string;
  parent_email: string;
  is_active: boolean;
}

export interface AttendanceRecord {
  id: string;
  student_id: string;
  camera_location: string;
  timestamp: string;
  confidence_score: number;
}

export interface AttendanceStats {
  total_students: number;
  present_students: number;
  absent_students: number;
  attendance_percentage: number;
  date: string;
}

export interface Announcement {
  id: string;
  title: string;
  content: string;
  author_id: string;
  author_name?: string;
  target_roles: string[];
  is_published: boolean;
  created_at: string;
  updated_at?: string;
}

export interface Notification {
  id: string;
  notification_type: string;
  recipient: string;
  title?: string;
  message: string;
  status: string;
  is_read: boolean;
  created_at: string;
}

export interface Mark {
  id: string;
  student_id: string;
  student_name: string;
  subject: string;
  term: string;
  score: number;
  max_score: number;
  percentage: number;
  grade?: string;
  remarks?: string;
  is_published: boolean;
  created_at: string;
}

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private authHeaders(): Record<string, string> {
    const token = pb.authStore.token;
    return token ? { Authorization: `Bearer ${token}` } : {};
  }

  async request(method: string, endpoint: string, data?: any, isForm = false): Promise<any> {
    const headers: Record<string, string> = { ...this.authHeaders() };
    if (data && !isForm) headers['Content-Type'] = 'application/json';

    const res = await fetch(`${this.baseUrl}/api/v1${endpoint}`, {
      method,
      headers,
      body: isForm ? data : data ? JSON.stringify(data) : undefined,
    });

    if (res.status === 401) {
      pb.authStore.clear();
      if (typeof window !== 'undefined') window.location.href = '/login';
      return;
    }
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || `${method} ${endpoint} failed`);
    }
    if (res.status === 204) return null;
    return res.json();
  }

  // Generic methods (used by cameras/settings pages)
  async get(endpoint: string): Promise<any> { return this.request('GET', endpoint); }
  async post(endpoint: string, data: any): Promise<any> { return this.request('POST', endpoint, data); }
  async put(endpoint: string, data: any): Promise<any> { return this.request('PUT', endpoint, data); }
  async delete(endpoint: string): Promise<any> { return this.request('DELETE', endpoint); }

  // Auth
  async login(email: string, password: string): Promise<AuthUser> {
    const form = new URLSearchParams({ username: email, password });
    const res = await fetch(`${this.baseUrl}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString(),
    });
    if (!res.ok) { const e = await res.json(); throw new Error(e.detail || 'Login failed'); }
    return res.json();
  }

  async registerStudent(data: any) { return this.request('POST', '/auth/register/student', data); }
  async registerParent(data: any) { return this.request('POST', '/auth/register/parent', data); }
  async getMe() { return this.request('GET', '/auth/me'); }

  // Students
  async getStudents(): Promise<Student[]> { return this.request('GET', '/students'); }
  async getStudent(id: string): Promise<Student> { return this.request('GET', `/students/${id}`); }
  async getMyStudentProfile(): Promise<Student> { return this.request('GET', '/students/me'); }
  async deleteStudent(id: string) { return this.request('DELETE', `/students/${id}`); }
  async createStudent(formData: FormData) { return this.request('POST', '/students', formData, true); }

  // Attendance
  async getTodayAttendance(): Promise<AttendanceRecord[]> { return this.request('GET', '/attendance/today'); }
  async getAttendanceStats(): Promise<AttendanceStats> { return this.request('GET', '/attendance/stats'); }
  async getMyAttendance(): Promise<AttendanceRecord[]> { return this.request('GET', '/attendance/my'); }
  async getAttendanceByDateRange(start: string, end: string) {
    return this.request('GET', `/attendance?start_date=${start}&end_date=${end}`);
  }

  // Announcements
  async getAnnouncements(): Promise<Announcement[]> { return this.request('GET', '/announcements'); }
  async createAnnouncement(data: any): Promise<Announcement> { return this.request('POST', '/announcements', data); }
  async deleteAnnouncement(id: string) { return this.request('DELETE', `/announcements/${id}`); }

  // Notifications
  async getNotifications(): Promise<Notification[]> { return this.request('GET', '/notifications'); }
  async getUnreadCount(): Promise<{ unread_count: number }> { return this.request('GET', '/notifications/unread-count'); }
  async markRead(id: string) { return this.request('POST', `/notifications/${id}/read`); }
  async markAllRead() { return this.request('POST', '/notifications/read-all'); }

  // Parent
  async getMyChildren() { return this.request('GET', '/parent/children'); }
  async linkChild(student_id: string) { return this.request('POST', '/parent/children/link', { student_id }); }
  async getChildAttendance(student_id: string) { return this.request('GET', `/parent/children/${student_id}/attendance`); }
  async getChildFees(student_id: string) { return this.request('GET', `/parent/children/${student_id}/fees`); }

  // Admin - Fees
  async getStudentFees(student_id: string) { return this.request('GET', `/admin/students/${student_id}/fees`); }
  async addStudentFee(student_id: string, data: any) { return this.request('POST', `/admin/students/${student_id}/fees`, data); }
  async updateFee(fee_id: string, data: any) { return this.request('PATCH', `/admin/fees/${fee_id}`, data); }
  async deleteFee(fee_id: string) { return this.request('DELETE', `/admin/fees/${fee_id}`); }

  // Reports
  async getWeeklyTrend() { return this.request('GET', '/reports/weekly-trend'); }
  async getLateArrivals(cutoffHour = 8) { return this.request('GET', `/reports/late-arrivals?cutoff_hour=${cutoffHour}`); }
  async markManualAttendance(studentId: string, location: string) {
    return this.request('POST', '/attendance/manual', { student_id: studentId, location });
  }
  async getDailySummary(date?: string) {
    return this.request('GET', `/reports/daily-summary${date ? `?report_date=${date}` : ''}`);
  }
  async getStudentReport(student_id: string, start: string, end: string) {
    return this.request('GET', `/reports/student/${student_id}?start_date=${start}&end_date=${end}`);
  }
  async getGradeSummary(date?: string) {
    return this.request('GET', `/reports/grade-summary${date ? `?report_date=${date}` : ''}`);
  }

  // Cameras
  async getCameras() { return this.request('GET', '/cameras'); }

  // Marks
  async getMarks(student_id?: string, term?: string, subject?: string): Promise<Mark[]> {
    let url = '/marks?';
    if (student_id) url += `student_id=${student_id}&`;
    if (term) url += `term=${term}&`;
    if (subject) url += `subject=${subject}&`;
    return this.request('GET', url);
  }
  async createMark(data: any): Promise<Mark> { return this.request('POST', '/marks', data); }
  async updateMark(id: string, data: any): Promise<Mark> { return this.request('PUT', `/marks/${id}`, data); }
  async deleteMark(id: string) { return this.request('DELETE', `/marks/${id}`); }
  async publishMark(id: string) { return this.request('POST', `/marks/${id}/publish`); }
  async getMyMarks(): Promise<Mark[]> { return this.request('GET', '/my-marks'); }
  async getChildMarks(student_id: string): Promise<Mark[]> { return this.request('GET', `/child-marks/${student_id}`); }
  async bulkUploadMarks(file: File, term: string): Promise<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.request('POST', `/marks/bulk?term=${encodeURIComponent(term)}`, formData);
  }
  async getSubjectAnalytics(subject: string, term: string): Promise<any> {
    return this.request('GET', `/marks/analytics/subject?subject=${encodeURIComponent(subject)}&term=${encodeURIComponent(term)}`);
  }
  async getConsolidatedReport(student_id: string, term: string): Promise<any> {
    return this.request('GET', `/marks/consolidated/${student_id}?term=${encodeURIComponent(term)}`);
  }
  async getGradingSchemes(): Promise<any[]> { return this.request('GET', '/admin/grading-schemes'); }
  async createGradingScheme(data: any) { return this.request('POST', '/admin/grading-schemes', data); }
  async deleteGradingScheme(id: string) { return this.request('DELETE', `/admin/grading-schemes/${id}`); }
}

export const api = new ApiClient(API_BASE_URL);
