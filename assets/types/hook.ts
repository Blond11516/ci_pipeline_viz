export interface Hook {
  mounted(): void;
}

export interface HookContext {
  el: HTMLElement;
}
