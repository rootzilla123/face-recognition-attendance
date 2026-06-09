# Senior UI Engineer Brief: Mobile & Desktop App Design

## Executive Summary

You've been brought in as a senior UI engineer to design and implement the user interfaces for two critical applications:

1. **Mobile App** (Flutter) - For students/parents to view attendance
2. **Desktop App** (Flutter Desktop) - For teachers to verify attendance

Both apps need to be **simple, fast, and reliable**. School staff and students should understand them in seconds. Every pixel should serve a purpose.

**Timeline**: 4 weeks to production-ready UI
**Platforms**: iOS, Android, Web (mobile) + Windows, Linux, macOS (desktop)
**Design System**: Unified, accessible, offline-first

---

## Your Mission

### Phase 1: Design System (Week 1 - 20 hours)
Create a comprehensive, reusable design system that both apps will use.

**Deliverables**:
1. **Color Palette** (4 hours)
   - Primary: Blue (#3B82F6)
   - Secondary: Green (#10B981)
   - Danger: Red (#EF4444)
   - Neutral: Gray scale
   - Dark mode variants

2. **Typography System** (4 hours)
   - Font family: Inter or Roboto
   - Scale: 10px to 32px
   - Weights: Regular, Medium, Bold
   - Line heights: 1.2 to 1.6

3. **Component Library** (8 hours)
   - Buttons (Primary, Secondary, Danger, Ghost)
   - Input fields (Text, Textarea, Dropdown, Date)
   - Cards (Standard, Elevated, Outlined)
   - Status indicators (Present, Absent, Pending)
   - Notifications (Success, Error, Warning, Info)
   - Loaders (Spinner, Skeleton, Progress)

4. **Spacing & Layout** (2 hours)
   - 8px grid system
   - Padding/margin scale
   - Responsive breakpoints
   - Safe areas (mobile notch, desktop edges)

5. **Animation Guidelines** (2 hours)
   - Entrance/exit animations
   - Hover states
   - Loading animations
   - Transition timings

**Success Criteria**:
- ✅ Design system documented
- ✅ All components designed
- ✅ Dark mode variants created
- ✅ Accessibility guidelines defined
- ✅ Figma/design file ready for handoff

---

### Phase 2: Mobile App UI (Week 2 - 30 hours)
Design all screens for the mobile app.

**Key Screens** (5 screens × 6 hours each):

1. **Login Screen** (6 hours)
   - Email/phone input
   - Password input
   - Sign in button
   - Sign up link
   - Forgot password link
   - Social login (optional)
   - Error states
   - Loading state

2. **Attendance History Screen** (6 hours)
   - Today's status (Present/Absent)
   - Attendance rate (%)
   - Date range filters
   - List of attendance records
   - Pull-to-refresh
   - Empty state
   - Error state

3. **Notifications Screen** (6 hours)
   - Notification list
   - Filter tabs (All, Unread, Alerts)
   - Notification types (System, Attendance, Email)
   - Timestamps
   - Swipe to delete
   - Mark as read
   - Empty state

4. **Profile Screen** (6 hours)
   - Avatar with initials
   - User info (name, email, ID)
   - Editable fields
   - Preferences (Dark mode, Language)
   - Change password
   - Logout
   - Delete account

5. **Parent View - Multi-Child** (6 hours)
   - Child cards
   - Quick status (Present/Absent)
   - Attendance rate
   - Drill-down to details
   - Add/remove children
   - Empty state

**Additional Screens**:
- Splash screen (1 hour)
- Onboarding flow (2 hours)
- Settings screen (2 hours)
- Offline indicator (1 hour)

**Success Criteria**:
- ✅ All screens designed
- ✅ Responsive layouts (portrait + landscape)
- ✅ Dark mode variants
- ✅ Accessibility annotations
- ✅ Interaction flows documented
- ✅ Prototype interactive

---

### Phase 3: Desktop App UI (Week 3 - 30 hours)
Design all screens for the desktop app.

**Key Screens** (4 screens × 7.5 hours each):

1. **Main Dashboard** (7.5 hours)
   - Split view: Camera + Attendance
   - Live MJPEG stream
   - Today's attendance summary
   - Class roster table
   - Quick action buttons
   - Status indicators
   - Keyboard shortcuts

2. **Attendance Verification Screen** (7.5 hours)
   - Detected face image (large)
   - Confidence score
   - Enrolled face comparison
   - Similarity percentage
   - Reason dropdown (for rejection)
   - Approve/Reject/Skip buttons
   - Keyboard shortcuts

3. **Manual Attendance Screen** (7.5 hours)
   - Search bar
   - Student list with status
   - Toggle buttons (Mark Present/Absent)
   - Bulk actions
   - Undo functionality
   - Save confirmation
   - Keyboard shortcuts

4. **Class Management Screen** (7.5 hours)
   - Class cards
   - Attendance statistics
   - Date range filters
   - Drill-down to details
   - Export functionality
   - Trends visualization

**Additional Screens**:
- Settings screen (2 hours)
- Camera configuration (2 hours)
- Offline indicator (1 hour)
- System tray menu (1 hour)

**Success Criteria**:
- ✅ All screens designed
- ✅ Responsive layouts (1366px to 4K)
- ✅ Dark mode variants
- ✅ Keyboard navigation documented
- ✅ Accessibility annotations
- ✅ Prototype interactive

---

### Phase 4: Implementation & Polish (Week 4 - 20 hours)
Implement UI in Flutter and ensure pixel-perfect accuracy.

**Mobile App Implementation** (10 hours):
- Convert designs to Flutter widgets
- Implement responsive layouts
- Add animations and transitions
- Test on iOS and Android
- Verify dark mode
- Test accessibility

**Desktop App Implementation** (10 hours):
- Convert designs to Flutter Desktop widgets
- Implement responsive layouts
- Add keyboard shortcuts
- Test on Windows, Linux, macOS
- Verify dark mode
- Test accessibility

**Success Criteria**:
- ✅ UI matches design 100%
- ✅ Responsive on all devices
- ✅ Dark mode working
- ✅ Animations smooth
- ✅ Accessibility verified
- ✅ Performance optimized

---

## Design Principles

### 1. Simplicity
- **Principle**: Remove everything that doesn't serve a purpose
- **Application**: 
  - No decorative elements
  - Clear hierarchy
  - Obvious call-to-action
  - Minimal text
- **Example**: Login screen has only email, password, sign in button

### 2. Speed
- **Principle**: Users should understand the app in seconds
- **Application**:
  - Obvious navigation
  - Clear status indicators
  - Quick actions
  - Minimal clicks to goal
- **Example**: Attendance history shows status at a glance

### 3. Reliability
- **Principle**: System should never surprise users
- **Application**:
  - Clear error messages
  - Confirmation for destructive actions
  - Offline indicators
  - Loading states
- **Example**: "Are you sure?" before deleting account

### 4. Accessibility
- **Principle**: Everyone should be able to use the app
- **Application**:
  - High contrast (4.5:1 ratio)
  - Large touch targets (48px)
  - Keyboard navigation
  - Screen reader support
- **Example**: All buttons are 48px tall on mobile

### 5. Consistency
- **Principle**: Same patterns across all screens
- **Application**:
  - Same button styles
  - Same color meanings
  - Same spacing
  - Same animations
- **Example**: Green always means "present", red always means "absent"

---

## Color Semantics

### Status Colors
- **Green (#10B981)**: Present, success, confirmed
- **Red (#EF4444)**: Absent, error, rejected
- **Amber (#F59E0B)**: Pending, warning, alert
- **Gray (#6B7280)**: Neutral, secondary, disabled
- **Blue (#3B82F6)**: Primary action, information

### Usage Rules
- **Never use red for success** (confuses users)
- **Never use green for errors** (contradicts expectations)
- **Always use consistent colors** (green = present everywhere)
- **Test with colorblind users** (don't rely on color alone)

---

## Typography Hierarchy

### Mobile App
```
Page Title: 24px Bold
Section Header: 20px Bold
Card Title: 16px Bold
Body Text: 16px Regular
Secondary Text: 14px Regular
Caption: 12px Regular
```

### Desktop App
```
Page Title: 28px Bold
Section Header: 24px Bold
Card Title: 18px Bold
Body Text: 14px Regular
Secondary Text: 12px Regular
Caption: 11px Regular
```

### Rules
- **Never smaller than 12px** (unreadable)
- **Never larger than 32px** (wastes space)
- **Use bold for hierarchy** (not size alone)
- **Maintain 1.4x line height** (readability)

---

## Spacing System

### 8px Grid
```
xs: 4px   (tight spacing)
sm: 8px   (small gaps)
md: 16px  (standard spacing)
lg: 24px  (large gaps)
xl: 32px  (extra large gaps)
2xl: 48px (huge gaps)
```

### Application
- **Button padding**: 12px (vertical) × 16px (horizontal)
- **Card padding**: 16px
- **Section spacing**: 24px
- **Page margins**: 16px (mobile), 24px (desktop)

### Rules
- **Always use multiples of 8px** (consistency)
- **Never mix spacing systems** (confusing)
- **Use consistent spacing** (same gap = same relationship)

---

## Component Specifications

### Button
```
States:
- Default: Blue background, white text
- Hover: Darker blue
- Active: Even darker blue
- Disabled: Gray, no interaction
- Loading: Spinner inside button

Sizes:
- Small: 32px height, 12px font
- Medium: 40px height, 14px font
- Large: 48px height, 16px font

Variants:
- Primary: Blue background
- Secondary: Gray background
- Danger: Red background
- Ghost: Transparent, colored text
```

### Input Field
```
States:
- Default: Gray border, white background
- Focus: Blue border, white background
- Error: Red border, light red background
- Disabled: Gray background, no interaction
- Filled: Shows entered value

Height: 40px (mobile), 36px (desktop)
Padding: 8px horizontal, 10px vertical
Font: 14px Regular
```

### Card
```
Variants:
- Standard: White background, subtle shadow
- Elevated: Stronger shadow
- Outlined: Border only, no shadow
- Filled: Colored background

Padding: 16px
Border radius: 8px
Shadow: 0 1px 3px rgba(0,0,0,0.1)
```

### Status Indicator
```
Present: ✓ Green (#10B981)
Absent: ✗ Red (#EF4444)
Pending: ? Gray (#6B7280)
Alert: ⚠️ Amber (#F59E0B)

Size: 20px icon + 14px text
Spacing: 8px between icon and text
```

---

## Responsive Design

### Mobile Breakpoints
```
Small: 320px - 480px (phones)
Medium: 481px - 768px (large phones, tablets)
Large: 769px+ (tablets in landscape)
```

### Desktop Breakpoints
```
Small: 1024px - 1366px (laptops)
Medium: 1367px - 1920px (desktop)
Large: 1921px+ (large monitors)
```

### Rules
- **Mobile first**: Design for small screens, scale up
- **Flexible layouts**: No fixed widths
- **Touch-friendly**: Large buttons and spacing
- **Readable**: Maintain font sizes across breakpoints

---

## Animation Guidelines

### Entrance Animations
- Duration: 200ms
- Easing: ease-out
- Example: Fade in + slide up

### Exit Animations
- Duration: 150ms
- Easing: ease-in
- Example: Fade out + slide down

### Hover Animations
- Duration: 100ms
- Easing: ease-out
- Example: Scale 1.05, shadow increase

### Loading Animations
- Duration: 1s (loop)
- Easing: linear
- Example: Rotating spinner

### Transition Animations
- Duration: 300ms
- Easing: ease-in-out
- Example: Color change, size change

### Rules
- **Keep animations under 300ms** (feels instant)
- **Use ease-out for entrance** (feels natural)
- **Use ease-in for exit** (feels natural)
- **Never animate everything** (distracting)

---

## Dark Mode Implementation

### Color Adjustments
```
Light Mode → Dark Mode
White (#FFFFFF) → #1F2937
Light Gray (#F9FAFB) → #111827
Dark Gray (#6B7280) → #D1D5DB
Black (#111827) → #F9FAFB
```

### Rules
- **Invert text colors** (light text on dark background)
- **Darken backgrounds** (not pure black)
- **Lighten accents** (slightly brighter)
- **Test contrast** (still 4.5:1 ratio)

---

## Accessibility Checklist

### Color
- [ ] Contrast ratio 4.5:1 for text
- [ ] Contrast ratio 3:1 for UI components
- [ ] Not relying on color alone
- [ ] Colorblind-friendly palette

### Typography
- [ ] Minimum 12px font size
- [ ] Line height 1.4 or greater
- [ ] Sufficient letter spacing
- [ ] Clear hierarchy

### Interactive Elements
- [ ] Minimum 48px touch targets (mobile)
- [ ] Minimum 44px touch targets (desktop)
- [ ] Visible focus indicators
- [ ] Keyboard navigation support

### Images & Icons
- [ ] Alt text for all images
- [ ] Icon + text for clarity
- [ ] Sufficient icon size (24px minimum)
- [ ] Clear icon meaning

### Forms
- [ ] Labels for all inputs
- [ ] Error messages clear
- [ ] Required fields marked
- [ ] Validation feedback

### Motion
- [ ] Animations under 300ms
- [ ] Respect prefers-reduced-motion
- [ ] No flashing (>3 per second)
- [ ] Clear loading states

---

## Offline UI Patterns

### Offline Indicator
```
┌─────────────────────────────┐
│ ⚠️ Offline - Using cached data │
│ [Retry]                     │
└─────────────────────────────┘
```

### Cached Data Badge
```
Data last synced: 2 hours ago
[Sync Now]
```

### Sync Status
```
Syncing... (spinner)
Sync failed - Retry
Synced successfully ✓
```

### Rules
- **Always show offline status** (don't hide it)
- **Show last sync time** (transparency)
- **Provide retry option** (user control)
- **Cache critical data** (attendance, notifications)

---

## Error Handling UI

### Network Error
```
❌ Connection Lost
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

### Rules
- **Be specific** (not "Error")
- **Suggest action** (Retry, Contact Support)
- **Show error code** (for support)
- **Use clear language** (not technical jargon)

---

## Loading States

### Skeleton Loading
- Gray placeholder shapes
- Matches content layout
- Subtle pulse animation
- Feels faster than spinner

### Spinner
- Rotating circle
- Centered on screen
- 1s rotation speed
- Use for full-page loads

### Progress Bar
- Linear progress indicator
- Shows percentage
- Use for file uploads
- Smooth animation

### Pulse
- Subtle opacity animation
- 2s cycle
- Use for background updates
- Doesn't distract

---

## Success States

### Checkmark Animation
- Green animated checkmark
- 500ms animation
- Followed by fade out
- Use for confirmations

### Toast Notification
- "Action completed successfully"
- Green background
- Auto-dismiss after 3s
- Swipe to dismiss

### Highlight Flash
- Green background flash
- 300ms animation
- Draws attention
- Use for important updates

### Confirmation Message
- "Changes saved"
- Subtle animation
- Auto-dismiss after 2s
- Reassures user

---

## Implementation Checklist

### Design Phase
- [ ] Design system created
- [ ] All screens designed
- [ ] Dark mode variants created
- [ ] Accessibility annotations added
- [ ] Interaction flows documented
- [ ] Prototype interactive
- [ ] Design handed off to developers

### Implementation Phase
- [ ] UI matches design 100%
- [ ] Responsive on all devices
- [ ] Dark mode working
- [ ] Animations smooth
- [ ] Accessibility verified
- [ ] Performance optimized
- [ ] Tested on real devices

### Testing Phase
- [ ] Visual regression testing
- [ ] Accessibility testing
- [ ] Performance testing
- [ ] Cross-browser testing
- [ ] Cross-device testing
- [ ] Offline mode testing
- [ ] Dark mode testing

---

## Design Tools & Handoff

### Recommended Tools
- **Design**: Figma (collaborative, web-based)
- **Prototyping**: Figma (interactive prototypes)
- **Handoff**: Figma (developers can inspect)
- **Version Control**: Git (design files)

### Handoff Process
1. Create Figma file with all screens
2. Organize into components
3. Add annotations (spacing, colors, fonts)
4. Create interactive prototype
5. Share with developers
6. Provide design tokens (colors, typography, spacing)
7. Document design decisions

### Design Tokens
```json
{
  "colors": {
    "primary": "#3B82F6",
    "success": "#10B981",
    "danger": "#EF4444"
  },
  "typography": {
    "heading": "24px Bold",
    "body": "16px Regular"
  },
  "spacing": {
    "sm": "8px",
    "md": "16px",
    "lg": "24px"
  }
}
```

---

## Success Metrics

### Design Quality
- ✅ Consistent across all screens
- ✅ Accessible (WCAG AA)
- ✅ Responsive on all devices
- ✅ Dark mode working
- ✅ Animations smooth

### User Experience
- ✅ Users understand app in <10 seconds
- ✅ Can complete tasks in <5 clicks
- ✅ Clear error messages
- ✅ Offline mode works
- ✅ No confusion about status

### Implementation
- ✅ UI matches design 100%
- ✅ Performance >60 FPS
- ✅ Load time <2 seconds
- ✅ No layout shifts
- ✅ Keyboard navigation works

---

## Timeline Summary

| Week | Focus | Hours | Deliverable |
|------|-------|-------|-------------|
| 1 | Design System | 20 | Colors, typography, components |
| 2 | Mobile App UI | 30 | 5 key screens + variants |
| 3 | Desktop App UI | 30 | 4 key screens + variants |
| 4 | Implementation | 20 | Flutter implementation |
| **Total** | | **100** | **Production-ready UI** |

---

## Key Reminders

1. **Mobile First**: Design for small screens, scale up
2. **Accessibility**: WCAG AA compliant
3. **Consistency**: Same patterns everywhere
4. **Simplicity**: Remove everything unnecessary
5. **Speed**: Users should understand instantly
6. **Reliability**: Clear feedback for all actions
7. **Offline**: Always show cached data
8. **Dark Mode**: Support from day one
9. **Testing**: Test on real devices
10. **Documentation**: Document all decisions

---

**Make it beautiful. Make it simple. Make it work.**

