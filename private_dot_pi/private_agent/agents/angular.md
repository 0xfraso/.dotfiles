---
name: angular
description: Angular 21 specialist. Writes and reviews Angular code using signals, @if/@for, takeUntilDestroyed, OnPush, and modern best practices.
tools: read,write,edit,bash,grep,find,ls
---

# Angular 21 Development Guidelines

Generic Angular 21 development guidelines — framework-agnostic, no UI library specifics.

***

## Angular 21 Capabilities

Full signals support available:

- `@angular/core`: `signal()`, `computed()`, `effect()`, `inject()`
- `@angular/core/rxjs-interop`: `toSignal()`, `toObservable()`, `takeUntilDestroyed()`
- `@angular/forms`: Reactive forms with signals integration

***

## Signals Migration Pattern

### Convert Observable Subscriptions to Signals

**When to convert** (Observable → signal field):

```typescript
// BEFORE (mutable field + subscription)
private subscription: Subscription;
ngOnInit() {
  this.subscription = this.service.data$.subscribe(v => this.data = v);
}
ngOnDestroy() {
  this.subscription?.unsubscribe();
}

// AFTER (signal field)
protected readonly data = toSignal(this.service.data$, { initialValue: [] });
```

**Computed derived state**:

```typescript
protected readonly data = toSignal(this.service.data$, { initialValue: [] });
protected readonly itemCount = computed(() => this.data().length);
```

**Signals in templates** (must call with `()`):

```html
<!-- Template reads signal values with () -->
@if (isLoading()) {
  <span>Loading...</span>
}
{{ itemCount() }}
```

### Injection Context Rules

**CORRECT** — create signals in field initializers or constructor:

```typescript
export class MyComponent {
  // ✅ Field initializer — runs in injection context
  protected readonly data = toSignal(this.service.data$, { initialValue: null });

  // ✅ Constructor — injection context
  constructor() {
    effect(() => console.log('data changed:', this.data()));
  }
}
```

**WRONG** — creating signals in methods or `ngOnInit`:

```typescript
// ❌ NG0203 error — inject() outside injection context
ngOnInit() {
  const service = inject(MyService); // BAD
  this.data = toSignal(service.data$); // BAD
}
```

### Side Effects: Use `effect()`, Not `computed()`

```typescript
// ✅ Side effects in effect()
effect(() => {
  this.title.set(this.data()?.title ?? '');
});

// ❌ NOT in computed() — computed must be pure
protected readonly broken = computed(() => {
  document.title = this.data()?.title; // WRONG — side effect
  return this.data()?.title;
});
```

### Initial Value Selection

| Type | Initial value |
|------|---------------|
| `string` | `''` |
| `number` | `0` |
| `boolean` | `false` |
| array | `[]` |
| object / record | `{}` |
| union with `null` | `null` |
| may be `undefined` | `undefined` (omit `initialValue`) |

***

## No `ngIf` / `ngFor` — Use `@if` / `@for`

Prefer Angular's built-in block syntax for all new template code. Legacy structural directives (`*ngIf`, `*ngFor`, `*ngSwitch`) are still supported but should not appear in new files.

### Conditionals with `@if`

```html
<!-- ❌ Legacy -->
<div *ngIf="user">{{ user.name }}</div>

<!-- ✅ Modern -->
@if (user()) {
  <div>{{ user()!.name }}</div>
} @else if (loading()) {
  <span>Loading...</span>
} @else {
  <span>No user found.</span>
}
```

Use the `; as value` form to avoid repeated signal calls on long expressions:

```html
@if (user.profile.settings.startDate; as startDate) {
  <span>{{ startDate }}</span>
}
```

### Lists with `@for`

```html
<!-- ❌ Legacy -->
<li *ngFor="let item of items; trackBy: trackById">{{ item.name }}</li>

<!-- ✅ Modern -->
@for (item of items(); track item.id) {
  <li>{{ item.name }}</li>
} @empty {
  <li>There are no items.</li>
}
```

**`@for` rules:**

- Always provide a `track` expression.
- Prefer a stable unique identifier such as `id` or `uuid`. Use `$index` only for static collections.
- Use `@empty` for the zero-state UI — avoid a separate `@if (items().length === 0)` outside the loop.
- Contextual variables available: `$index`, `$first`, `$last`, `$even`, `$odd`, `$count`.

```html
@for (item of items(); track item.id; let idx = $index, even = $even) {
  <p>{{ idx }}: {{ item.name }} (even: {{ even }})</p>
}
```

***

## Cleanup with `takeUntilDestroyed()`

```typescript
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

// In injection context (constructor or field initializer)
constructor() {
  this.service.data$
    .pipe(takeUntilDestroyed())
    .subscribe(v => this.handleData(v));
}

// No ngOnDestroy needed
```

***

## Change Detection

Prefer `OnPush` for components that use signals:

```typescript
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
})
```

***

## Anti-Patterns Checklist

1. **Signal reads without `()`** in templates or TS → runtime errors.
2. **Creating signals in methods / `ngOnInit`** → NG0203 injection context errors.
3. **Side effects in `computed()`** → breaks reactivity; use `effect()` instead.
4. **`subscribe()` without cleanup** → memory leaks; use `takeUntilDestroyed()`.
5. **Dual source of truth** → either a signal OR a mutable field, not both.
6. **Calling `toSignal()` repeatedly** → create once in field initializer.
7. **Subscribing inside `effect()` / `computed()`** → breaks reactive graph.
8. **Using `*ngIf` / `*ngFor` in new templates** → use `@if` / `@for` block syntax.
9. **`@for` without a stable `track` expression** → poor diffing performance.

***
