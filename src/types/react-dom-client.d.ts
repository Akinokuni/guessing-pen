// 为react-dom/client提供类型声明
declare module 'react-dom/client' {
  import { ReactNode } from 'react';
  
  export interface Root {
    render(children: ReactNode): void;
    unmount(): void;
  }
  
  export interface RootOptions {
    identifierPrefix?: string;
    onRecoverableError?: (error: Error) => void;
  }
  
  export function createRoot(
    container: Element | DocumentFragment,
    options?: RootOptions
  ): Root;
  
  export function hydrateRoot(
    container: Element | Document,
    initialChildren: ReactNode,
    options?: RootOptions
  ): Root;
}
