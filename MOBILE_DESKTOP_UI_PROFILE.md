# Mobile & Desktop App UI/UX Profile

## Design Philosophy

**Core Principle**: Simple, fast, reliable. School staff and students should understand the app in seconds, not minutes.

**Design Language**: Modern, clean, minimal. No unnecessary animations or decorations. Every pixel serves a purpose.
cli
**Color Palette**: 
- Primary: Blue (#3B82F6) - Trust, reliability
- Secondary: Green (#10B981) - Success, present
- Danger: Red (#EF4444) - Absent, errors
- Neutral: Gray (#6B7280) - Secondary info
- Background: White (#FFFFFF) or Light Gray (#F9FAFB)

**Typography**:
- Headlines: Bold, clear, scannable
- Body: Regular weight, high contrast
- Captions: Smaller, secondary information

---

## Mobile App UI Profile

### Target Users
- **Students** (ages 12-18): Quick check-in, see attendance
- **Parents** (ages 30-60): Monitor child's attendance, receive notifications

### Device Constraints
- Screen size: 5.5" - 6.7" (typical smartphone)
- Orientation: Portrait primary, landscape secondary
- Network: Variable (4G, WiFi, sometimes offline)
- Battery: Limited (app should be efficient)

### Key Screens

#### 1. Login Screen
**Purpose**: Authenticate user (student or parent)

**Layout**:
```
┌─────────────────────────┐
│                         │
│    [Logo]               │
│    AttendanceAI         │
│                         │
│  ┌───────────────────┐  │
│  │ Email/Phone       │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Password          │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ Sign In           │  │
│  └───────────────────┘  │
│                         │
│  Don't have account?    │
│  [Sign Up]              │
│                         │
└─────────────────────────┘
```

**Design Notes**:
- Large, tappable buttons (48px minimum)
- Clear error messages
- "Forgot password?" link visible
- Social login optional (Google, Apple)
- Dark mode support

---

#### 2. Attendance History Screen
**Purpose**: View all attendance records

**Layout**:
```
┌─────────────────────────┐
│ ← Attendance            │
├─────────────────────────┤
│ Today: Present ✓        │
│ Attendance Rate: 95%    │
├─────────────────────────┤
│ [This Week] [This Month]│
├─────────────────────────┤
│ Mon 5/1  Present  ✓     │
│ Tue 5/2  Present  ✓     │
│ Wed 5/3  Absent   ✗     │
│ Thu 5/4  Present  ✓     │
│ Fri 5/5  Present  ✓     │
│                         │
│ [Load More]             │
└─────────────────────────┘
```

**Design Notes**:
- Green checkmark for present
- Red X for absent
- Date and day of week
- Swipe to filter by date range
- Pull-to-refresh
- Smooth scrolling

---

#### 3. Notifications Screen
**Purpose**: View received notifications

**Layout**:
```
┌─────────────────────────┐
│ ← Notifications         │
├─────────────────────────┤
│ [All] [Unread] [Alerts] │
├─────────────────────────┤
│ ⚠️ System Alert         │
│ Face recognition down   │
│ 2 hours ago             │
│ [Mark as read]          │
├─────────────────────────┤
│ ✓ Attendance Confirmed  │
│ You were marked present │
│ 1 day ago               │
├─────────────────────────┤
│ 📧 Email Notification   │
│ Weekly attendance report│
│ 3 days ago              │
│                         │
│ [Clear All]             │
└─────────────────────────┘
```

**Design Notes**:
- Icon indicates notification type
- Timestamp relative (2 hours ago)
- Swipe to delete
- Tap to view details
- Badge count on tab

---

#### 4. Profile Screen
**Purpose**: View and edit user profile

**Layout**:
```
┌─────────────────────────┐
│ ← Profile               │
├─────────────────────────┤
│      [Avatar]           │
│    John Doe             │
│    john@school.edu      │
├─────────────────────────┤
│ Student ID: 12345       │
│ Class: 10-A             │
│ Enrollment: Jan 2024    │
├─────────────────────────┤
│ Preferences             │
│ ├─ Notifications        │
│ ├─ Dark Mode            │
│ └─ Language             │
├─────────────────────────┤
│ [Change Password]       │
│ [Logout]                │
│ [Delete Account]        │
└─────────────────────────┘
```

**Design Notes**:
- Avatar with initials fallback
- Editable fields
- Toggle switches for preferences
- Destructive actions in red
- Confirmation dialogs

---

#### 5. Parent View (Multi-Child)
**Purpose**: Monitor multiple children

**Layout**:
```
┌─────────────────────────┐
│ ← My Children           │
├─────────────────────────┤
│ John Doe                │
│ Present Today ✓         │
│ Attendance: 95%         │
│ [View Details]          │
├─────────────────────────┤
│ Jane Doe                │
│ Present Today ✓         │
│ Attendance: 98%         │
│ [View Details]          │
├─────────────────────────┤
│ [Add Child]             │
└─────────────────────────┘
```

**Design Notes**:
- Card-based layout
- Quick status indicator
- Tap to see full details
- Add/remove children

---

### Mobile App Color Scheme

| Element | Color | Usage |
|---------|-------|-------|
| Primary Button | Blue (#3B82F6) | Main actions |
| Success | Green (#10B981) | Present, confirmed |
| Danger | Red (#EF4444) | Absent, errors |
| Warning | Amber (#F59E0B) | Alerts, pending |
| Background | White (#FFFFFF) | Main background |
| Surface | Gray (#F9FAFB) | Cards, sections |
| Text Primary | Gray (#111827) | Headlines, body |
| Text Secondary | Gray (#6B7280) | Captions, hints |
| Border | Gray (#E5E7EB) | Dividers, borders |

---

## Desktop App UI Profile

### Target Users
- **Teachers** (ages 25-65): Verify attendance, manage classes
- **Admin** (ages 30-70): Configure system, manage users

### Device Constraints
- Screen size: 13" - 27" (typical laptop/desktop)
- Orientation: Landscape primary
- Network: Stable (LAN or WiFi)
- Input: Keyboard + Mouse

### Key Screens

#### 1. Main Dashboard
**Purpose**: Overview of current attendance session

**Layout**:
```
┌──────────────────────────────────────────────────────────┐
│ AttendanceAI - Teacher Dashboard                    [≡]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────┐  ┌──────────────────────────┐  │
│  │  Live Camera Feed   │  │ Today's Attendance       │  │
│  │                     │  │ ┌────────────────────┐   │  │
│  │   [MJPEG Stream]    │  │ │ Present: 28/30     │   │  │
│  │                     │  │ │ Absent: 2          │   │  │
│  │                     │  │ │ Rate: 93%          │   │  │
│  │                     │  │ └────────────────────┘   │  │
│  │                     │  │                          │  │
│  │  [Mute] [Fullscreen]│  │ [Start Session]          │  │
│  └─────────────────────┘  └──────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Class: 10-A                                      │   │
│  │ ┌──────────────────────────────────────────────┐ │   │
│  │ │ Name          │ Status    │ Time      │ Action│ │   │
│  │ ├──────────────────────────────────────────────┤ │   │
│  │ │ John Doe      │ ✓ Present │ 08:15 AM  │ [✓]  │ │   │
│  │ │ Jane Smith    │ ✓ Present │ 08:16 AM  │ [✓]  │ │   │
│  │ │ Bob Johnson   │ ? Pending │ --:-- --  │ [✓][✗]│ │   │
│  │ │ Alice Brown   │ ✗ Absent  │ --:-- --  │ [✓]  │ │   │
│  │ └──────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Split view: Camera + Attendance
- Real-time updates
- Quick action buttons
- Keyboard shortcuts (Y for yes, N for no)
- Fullscreen camera option

---

#### 2. Attendance Verification Screen
**Purpose**: Approve/reject detected faces

**Layout**:
```
┌──────────────────────────────────────────────────────────┐
│ Verify Attendance                                   [X]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │                                                    │  │
│  │         [Detected Face Image]                     │  │
│  │                                                    │  │
│  │         John Doe (95% confidence)                 │  │
│  │                                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Enrolled Face:                                     │  │
│  │ [Enrolled Photo]                                   │  │
│  │ Similarity: 94%                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Reason (if rejecting):                             │  │
│  │ [Dropdown: Select reason...]                       │  │
│  │ - Face not clear                                   │  │
│  │ - Wrong person                                     │  │
│  │ - Multiple faces                                   │  │
│  │ - Other                                            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  [Approve] [Reject] [Skip]                              │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Large face images for clarity
- Confidence score visible
- Comparison with enrolled photo
- Keyboard shortcuts (A=Approve, R=Reject, S=Skip)
- Reason dropdown for rejections

---

#### 3. Manual Attendance Screen
**Purpose**: Mark attendance manually

**Layout**:
```
┌──────────────────────────────────────────────────────────┐
│ Manual Attendance                                   [X]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Search: [_________________]  [Clear]                   │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Name              │ Status    │ Action             │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ John Doe          │ ✓ Present │ [Mark Absent]      │  │
│  │ Jane Smith        │ ✗ Absent  │ [Mark Present]     │  │
│  │ Bob Johnson       │ ? Pending │ [Mark Present]     │  │
│  │ Alice Brown       │ ✓ Present │ [Mark Absent]      │  │
│  │ Charlie Davis     │ ? Pending │ [Mark Present]     │  │
│  │                   │           │ [Mark Absent]      │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  [Bulk Mark Present] [Bulk Mark Absent]                 │
│  [Undo Last] [Save]                                     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Search to find students quickly
- Toggle buttons for quick marking
- Bulk actions for efficiency
- Undo functionality
- Save confirmation

---

#### 4. Class Management Screen
**Purpose**: Manage classes and view attendance summary

**Layout**:
```
┌──────────────────────────────────────────────────────────┐
│ Classes                                             [≡]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  [Today] [This Week] [This Month] [Custom Range]        │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Class 10-A                                         │  │
│  │ Students: 30 | Present: 28 | Absent: 2            │  │
│  │ Attendance Rate: 93%                               │  │
│  │ [View Details] [Export]                            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Class 10-B                                         │  │
│  │ Students: 32 | Present: 30 | Absent: 2            │  │
│  │ Attendance Rate: 94%                               │  │
│  │ [View Details] [Export]                            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Class 10-C                                         │  │
│  │ Students: 28 | Present: 25 | Absent: 3            │  │
│  │ Attendance Rate: 89%                               │  │
│  │ [View Details] [Export]                            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Design Notes**:
- Card-based layout
- Key metrics visible at a glance
- Date range filters
- Export functionality
- Drill-down to details

---

### Desktop App Color Scheme

| Element | Color | Usage |
|---------|-------|-------|
| Primary Button | Blue (#3B82F6) | Main actions |
| Success | Green (#10B981) | Present, confirmed |
| Danger | Red (#EF4444) | Absent, errors |
| Warning | Amber (#F59E0B) | Alerts, pending |
| Background | White (#FFFFFF) | Main background |
| Surface | Gray (#F9FAFB) | Cards, panels |
| Sidebar | Gray (#F3F4F6) | Navigation |
| Text Primary | Gray (#111827) | Headlines, body |
| Text Secondary | Gray (#6B7280) | Captions, hints |
| Border | Gray (#E5E7EB) | Dividers, borders |
| Hover | Gray (#F0F1F3) | Interactive elements |

---

## Shared Design Principles

### 1. Accessibility
- Minimum font size: 14px (mobile), 12px (desktop)
- Color contrast ratio: 4.5:1 for text
- Touch targets: 48px minimum (mobile)
- Keyboard navigation: Full support (desktop)
- Screen reader support: ARIA labels

### 2. Performance
- Load time: <2 seconds
- Animation duration: <300ms
- Smooth scrolling: 60 FPS
- Lazy loading: Images and lists
- Offline support: Cache critical data

### 3. Responsiveness
- Mobile: 320px - 480px
- Tablet: 481px - 1024px
- Desktop: 1025px+
- Flexible layouts: No fixed widths
- Touch-friendly: Large buttons and spacing

### 4. Consistency
- Same color palette across apps
- Same typography scale
- Same spacing system (8px grid)
- Same button styles
- Same error messages

### 5. Feedback
- Loading states: Spinners, progress bars
- Success states: Checkmarks, green highlights
- Error states: Red highlights, error messages
- Confirmation dialogs: For destructive actions
- Toast notifications: For quick feedback

---

## Component Library

### Buttons
- **Primary**: Blue background, white text
- **Secondary**: Gray background, dark text
- **Danger**: Red background, white text
- **Ghost**: Transparent, colored text
- **Disabled**: Gray, no interaction

### Input Fields
- **Text**: Single line, 40px height
- **Textarea**: Multi-line, 100px height
- **Dropdown**: Select from options
- **Date Picker**: Calendar interface
- **Search**: With clear button

### Cards
- **Standard**: White background, subtle shadow
- **Elevated**: Stronger shadow
- **Outlined**: Border only, no shadow
- **Filled**: Colored background

### Status Indicators
- **Present**: Green checkmark
- **Absent**: Red X
- **Pending**: Gray question mark
- **Alert**: Orange warning icon

### Notifications
- **Success**: Green background, checkmark
- **Error**: Red background, X icon
- **Warning**: Amber background, warning icon
- **Info**: Blue background, info icon

---

## Typography Scale

| Size | Weight | Usage |
|------|--------|-------|
| 32px | Bold | Page titles |
| 24px | Bold | Section headers |
| 20px | Bold | Card titles |
| 16px | Regular | Body text |
| 14px | Regular | Secondary text |
| 12px | Regular | Captions |
| 10px | Regular | Hints |

---

## Spacing System (8px Grid)

| Size | Pixels | Usage |
|------|--------|-------|
| xs | 4px | Tight spacing |
| sm | 8px | Small gaps |
| md | 16px | Standard spacing |
| lg | 24px | Large gaps |
| xl | 32px | Extra large gaps |
| 2xl | 48px | Huge gaps |

---

## Animation Guidelines

- **Entrance**: 200ms ease-out
- **Exit**: 150ms ease-in
- **Hover**: 100ms ease-out
- **Loading**: Continuous, 1s loop
- **Transition**: 300ms ease-in-out

---

## Dark Mode Support

- Background: #1F2937
- Surface: #111827
- Text Primary: #F9FAFB
- Text Secondary: #D1D5DB
- Border: #374151
- Accent colors: Slightly lighter

---

## Offline Indicators

- **Online**: Green dot, "Connected"
- **Offline**: Gray dot, "Offline - Using cached data"
- **Syncing**: Blue dot, "Syncing..."
- **Error**: Red dot, "Sync failed - Retry"

---

## Error Handling UI

### Network Error
```
⚠️ Connection Lost
Unable to reach server. 
Using cached data.
[Retry] [Dismiss]
```

### Validation Error
```
❌ Invalid Input
Email address is not valid.
[OK]
```

### Server Error
```
❌ Something Went Wrong
Please try again later.
Error Code: 500
[Retry] [Contact Support]
```

---

## Loading States

- **Skeleton Loading**: Gray placeholder shapes
- **Spinner**: Rotating circle animation
- **Progress Bar**: Linear progress indicator
- **Pulse**: Subtle opacity animation

---

## Success States

- **Checkmark**: Green animated checkmark
- **Toast**: "Action completed successfully"
- **Highlight**: Green background flash
- **Confirmation**: "Changes saved"

---

## Notes for UI Engineer

1. **Mobile First**: Design for mobile, then scale up
2. **Touch Friendly**: All interactive elements 48px+
3. **Readable**: High contrast, large fonts
4. **Fast**: Minimal animations, quick feedback
5. **Consistent**: Use component library
6. **Accessible**: WCAG AA compliant
7. **Offline**: Always show cached data
8. **Errors**: Clear, actionable messages
9. **Feedback**: Always confirm user actions
10. **Testing**: Test on real devices

