# Component Library

## Atomic Design System

Built on design tokens. Atoms → Molecules → Organisms.

---

## 🔬 Atoms (Basic Elements)

### Button

Primary action component with variants and sizes.

```tsx
import Button from '@/app/components/atoms/Button';

// Primary (default)
<Button onClick={handleClick}>
  Click Me
</Button>

// Variants
<Button variant="primary">Primary</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="danger">Delete</Button>
<Button variant="ghost">Ghost</Button>

// Sizes
<Button size="sm">Small</Button>
<Button size="md">Medium</Button>
<Button size="lg">Large</Button>

// States
<Button disabled>Disabled</Button>
<Button type="submit">Submit</Button>
```

**Design Tokens Used:**
- Spacing: `px-4 py-2` (sm), `px-6 py-3` (md), `px-8 py-4` (lg)
- Colors: `primary-600`, `secondary-600`, `error-600`
- Radius: `rounded-lg` (16px)
- Typography: `text-small`, `text-body`, `text-h3`

---

### Input

Form input with label, error, and helper text.

```tsx
import Input from '@/app/components/atoms/Input';

// Basic
<Input 
  placeholder="Enter text"
/>

// With label
<Input 
  label="Email Address"
  type="email"
  placeholder="you@example.com"
/>

// With error
<Input 
  label="Password"
  type="password"
  error="Password is required"
/>

// With helper text
<Input 
  label="Username"
  helperText="Choose a unique username"
/>

// Disabled
<Input 
  label="Disabled"
  disabled
  value="Cannot edit"
/>
```

**Design Tokens Used:**
- Spacing: `px-4 py-3` (padding), `space-y-1` (gap)
- Colors: `border-gray-300`, `focus:ring-primary-500`
- Radius: `rounded-lg` (16px)
- Typography: `text-small` (label), `text-body` (input), `text-caption` (helper)

---

### Card

Container component with elevation variants.

```tsx
import Card from '@/app/components/atoms/Card';

// Default
<Card>
  <h3>Card Title</h3>
  <p>Card content</p>
</Card>

// Variants
<Card variant="default">Default shadow</Card>
<Card variant="elevated">Elevated shadow</Card>
<Card variant="outlined">Outlined border</Card>

// Padding
<Card padding="sm">Small padding (32px)</Card>
<Card padding="md">Medium padding (48px)</Card>
<Card padding="lg">Large padding (64px)</Card>

// Hover effect
<Card hover>
  Scales up on hover
</Card>
```

**Design Tokens Used:**
- Spacing: `p-4` (sm), `p-6` (md), `p-8` (lg)
- Shadows: `shadow-md`, `shadow-lg`
- Radius: `rounded-2xl` (24px)
- Border: `border-2 border-gray-200`

---

### Badge

Small status indicator with semantic colors.

```tsx
import Badge from '@/app/components/atoms/Badge';

// Variants
<Badge variant="primary">Primary</Badge>
<Badge variant="secondary">Secondary</Badge>
<Badge variant="success">Success</Badge>
<Badge variant="error">Error</Badge>
<Badge variant="warning">Warning</Badge>
<Badge variant="info">Info</Badge>

// Sizes
<Badge size="sm">Small</Badge>
<Badge size="md">Medium</Badge>

// Usage example
<div className="flex gap-2">
  <Badge variant="success">Active</Badge>
  <Badge variant="error">Offline</Badge>
  <Badge variant="warning">Pending</Badge>
</div>
```

**Design Tokens Used:**
- Spacing: `px-2 py-1` (sm), `px-3 py-1` (md)
- Colors: Semantic color tokens (success-100, error-100, etc.)
- Radius: `rounded-full` (pill shape)
- Typography: `text-caption` (sm), `text-small` (md)

---

## 🧪 Molecules (Composite Components)

### Form Field

Input with label in a consistent layout.

```tsx
<div className="space-y-4">
  <Input 
    label="Full Name"
    placeholder="John Doe"
  />
  <Input 
    label="Email"
    type="email"
    placeholder="john@example.com"
  />
  <Button variant="primary" size="lg">
    Submit
  </Button>
</div>
```

---

### Stat Card

Card with icon, value, and label.

```tsx
<Card padding="md" hover>
  <div className="flex items-center gap-4">
    <div className="w-12 h-12 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-2xl flex items-center justify-center text-2xl">
      👥
    </div>
    <div>
      <p className="text-caption text-gray-600">Total Students</p>
      <p className="text-h2 font-bold">1,234</p>
    </div>
  </div>
</Card>
```

---

### Button Group

Multiple buttons in a row.

```tsx
<div className="flex gap-3">
  <Button variant="secondary">Cancel</Button>
  <Button variant="primary">Save</Button>
</div>
```

---

## 🔬 Organisms (Complex Components)

### Modal

Full modal with header, body, and actions.

```tsx
<div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-modal">
  <Card padding="lg" className="max-w-2xl w-full">
    {/* Header */}
    <div className="mb-6">
      <h2 className="text-h2">Modal Title</h2>
      <p className="text-small text-gray-600">Modal description</p>
    </div>
    
    {/* Body */}
    <div className="space-y-4 mb-6">
      <Input label="Field 1" />
      <Input label="Field 2" />
    </div>
    
    {/* Actions */}
    <div className="flex gap-3">
      <Button variant="secondary">Cancel</Button>
      <Button variant="primary">Confirm</Button>
    </div>
  </Card>
</div>
```

---

### Data Table

Table with consistent styling.

```tsx
<Card padding="lg">
  <table className="w-full">
    <thead className="bg-gray-50">
      <tr>
        <th className="text-left py-3 px-4 text-small font-semibold text-gray-700">
          Name
        </th>
        <th className="text-left py-3 px-4 text-small font-semibold text-gray-700">
          Status
        </th>
      </tr>
    </thead>
    <tbody>
      <tr className="border-t border-gray-100 hover:bg-gray-50">
        <td className="py-3 px-4 text-body">John Doe</td>
        <td className="py-3 px-4">
          <Badge variant="success">Active</Badge>
        </td>
      </tr>
    </tbody>
  </table>
</Card>
```

---

## 📐 Layout Patterns

### Grid Layout

```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <Card>Item 1</Card>
  <Card>Item 2</Card>
  <Card>Item 3</Card>
  <Card>Item 4</Card>
</div>
```

### Stack Layout

```tsx
<div className="space-y-6">
  <Card>Section 1</Card>
  <Card>Section 2</Card>
  <Card>Section 3</Card>
</div>
```

### Flex Layout

```tsx
<div className="flex items-center justify-between gap-4">
  <h1 className="text-h1">Title</h1>
  <Button>Action</Button>
</div>
```

---

## 🎨 Design Token Reference

### Spacing (8px system)
```
gap-1  → 8px
gap-2  → 16px
gap-3  → 24px
gap-4  → 32px
gap-6  → 48px
gap-8  → 64px
```

### Colors
```
bg-primary-500
text-secondary-600
border-gray-300
```

### Typography
```
text-display → 48px
text-h1      → 38px
text-h2      → 30px
text-h3      → 24px
text-body    → 16px
text-small   → 14px
text-caption → 12px
```

### Radius
```
rounded-sm   → 8px
rounded-lg   → 16px
rounded-2xl  → 24px
rounded-full → pill
```

---

## ✅ Best Practices

1. **Always use atoms** - Don't create one-off components
2. **Stick to tokens** - No arbitrary values
3. **Compose molecules** - Build complex from simple
4. **Maintain consistency** - Same patterns everywhere
5. **Document usage** - Help others understand

---

## 🚀 Quick Start

```tsx
import Button from '@/app/components/atoms/Button';
import Input from '@/app/components/atoms/Input';
import Card from '@/app/components/atoms/Card';
import Badge from '@/app/components/atoms/Badge';

function MyComponent() {
  return (
    <Card padding="lg">
      <h2 className="text-h2 mb-4">Form Title</h2>
      
      <div className="space-y-4 mb-6">
        <Input 
          label="Name"
          placeholder="Enter name"
        />
        <Input 
          label="Email"
          type="email"
          placeholder="Enter email"
        />
      </div>
      
      <div className="flex items-center justify-between">
        <Badge variant="success">Active</Badge>
        <div className="flex gap-3">
          <Button variant="secondary">Cancel</Button>
          <Button variant="primary">Submit</Button>
        </div>
      </div>
    </Card>
  );
}
```

**Small tokens. Big systems. Every pixel intentional.** 🎨
