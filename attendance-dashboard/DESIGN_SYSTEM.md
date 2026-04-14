# Design System Documentation

## 🎨 Design Tokens

A comprehensive design system built on atomic principles. Every pixel is intentional.

---

## Color System

### Primary (Blue) - Monochromatic
Main brand color with full lightness scale.

```
primary-50  → #eff6ff (Lightest)
primary-100 → #dbeafe
primary-200 → #bfdbfe
primary-300 → #93c5fd
primary-400 → #60a5fa
primary-500 → #3b82f6 (Base)
primary-600 → #2563eb
primary-700 → #1d4ed8
primary-800 → #1e40af
primary-900 → #1e3a8a (Darkest)
```

### Secondary (Purple) - Complementary
Complementary color for contrast and harmony.

```
secondary-50  → #faf5ff
secondary-500 → #a855f7 (Base)
secondary-900 → #581c87
```

### Semantic Colors
Purpose-driven colors for UI feedback.

```
success-500 → #22c55e (Green)
error-500   → #ef4444 (Red)
warning-500 → #eab308 (Yellow)
info-500    → #3b82f6 (Blue)
```

---

## Typography Scale

### Modular Scale (1.25 ratio)
Each size is 1.25x the previous. Creates natural hierarchy.

```
display → 48px (3rem)    - Hero text, landing pages
h1      → 38px (2.375rem) - Page titles
h2      → 30px (1.875rem) - Section headers
h3      → 24px (1.5rem)   - Subsection headers
body    → 16px (1rem)     - Default text
small   → 14px (0.875rem) - Secondary text
caption → 12px (0.75rem)  - Labels, metadata
```

### Usage
```tsx
<h1 className="text-h1">Page Title</h1>
<h2 className="text-h2">Section Header</h2>
<p className="text-body">Body text</p>
<span className="text-small">Secondary text</span>
```

---

## Spacing System

### 8px Base Unit
All spacing is a multiple of 8. Creates visual rhythm.

```
0  → 0px
1  → 8px    (8 × 1)
2  → 16px   (8 × 2)
3  → 24px   (8 × 3)
4  → 32px   (8 × 4)
5  → 40px   (8 × 5)
6  → 48px   (8 × 6)
8  → 64px   (8 × 8)
10 → 80px   (8 × 10)
12 → 96px   (8 × 12)
16 → 128px  (8 × 16)
20 → 160px  (8 × 20)
```

### Usage
```tsx
// Padding
<div className="p-4">32px padding</div>
<div className="px-6 py-3">48px horizontal, 24px vertical</div>

// Margin
<div className="mb-8">64px bottom margin</div>

// Gap
<div className="flex gap-3">24px gap between items</div>
```

---

## Border Radius

### Consistent Curves
Rounded corners create friendly, modern feel.

```
sm   → 8px   - Small elements (badges, tags)
md   → 12px  - Medium elements (inputs, small cards)
lg   → 16px  - Large elements (buttons, cards)
xl   → 20px  - Extra large (modals, large cards)
2xl  → 24px  - Hero elements
full → 9999px - Circles, pills
```

### Usage
```tsx
<button className="rounded-lg">Button</button>
<div className="rounded-2xl">Card</div>
<span className="rounded-full">Badge</span>
```

---

## Shadows

### Depth System
Shadows create hierarchy and depth.

```
sm   → Subtle elevation
md   → Default elevation
lg   → Prominent elevation
xl   → High elevation
2xl  → Maximum elevation (modals)
```

### Usage
```tsx
<div className="shadow-sm">Subtle card</div>
<div className="shadow-lg">Prominent card</div>
<div className="shadow-2xl">Modal</div>
```

---

## Atomic Design

### Atoms (Basic Elements)
- Button
- Input
- Badge
- Icon

### Molecules (Simple Components)
- Input with Label
- Button Group
- Card Header

### Organisms (Complex Components)
- Modal
- Card
- Form
- Navigation

---

## Component Examples

### Button (Atom)
```tsx
// Primary
<button className="px-6 py-3 bg-gradient-to-r from-primary-600 to-secondary-600 text-white rounded-lg shadow-lg hover:shadow-xl transition-all">
  Primary Button
</button>

// Secondary
<button className="px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-all">
  Secondary Button
</button>
```

### Card (Molecule)
```tsx
<div className="bg-white rounded-2xl shadow-lg p-6 space-y-4">
  <h3 className="text-h3">Card Title</h3>
  <p className="text-body text-gray-600">Card content</p>
</div>
```

### Input (Atom)
```tsx
<input 
  type="text"
  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all"
  placeholder="Enter text"
/>
```

---

## Design Principles

### 1. Consistency
Every component uses the same tokens. No random values.

### 2. Hierarchy
Typography and spacing create clear visual hierarchy.

### 3. Rhythm
8px spacing grid creates visual rhythm and alignment.

### 4. Intentionality
Every pixel has a purpose. Nothing is arbitrary.

### 5. Scalability
Tokens make it easy to maintain and scale the design.

---

## Usage Guidelines

### ✅ DO
- Use spacing tokens (p-4, m-6, gap-3)
- Use color tokens (bg-primary-500, text-secondary-600)
- Use typography scale (text-h1, text-body)
- Use border radius tokens (rounded-lg, rounded-2xl)

### ❌ DON'T
- Use arbitrary values (p-[13px], m-[27px])
- Use random colors (#3b82f6 directly)
- Use random font sizes (text-[19px])
- Use random border radius (rounded-[13px])

---

## Benefits

1. **Consistency** - Everything looks cohesive
2. **Speed** - No decisions, just use tokens
3. **Maintainability** - Change once, update everywhere
4. **Professionalism** - Intentional design shows quality
5. **Scalability** - Easy to add new components

---

## The System in Action

```tsx
// Before (Random values)
<div className="p-[13px] m-[27px] rounded-[15px] text-[19px]">
  Inconsistent
</div>

// After (System tokens)
<div className="p-4 m-6 rounded-lg text-body">
  Intentional
</div>
```

**Small tokens. Big systems. Every pixel intentional.** 🎨
