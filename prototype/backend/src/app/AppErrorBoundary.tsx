import { Component, type ErrorInfo, type ReactNode } from 'react';

interface AppErrorBoundaryProps {
  children: ReactNode;
}

interface AppErrorBoundaryState {
  hasError: boolean;
}

export class AppErrorBoundary extends Component<
  AppErrorBoundaryProps,
  AppErrorBoundaryState
> {
  public state: AppErrorBoundaryState = { hasError: false };

  public static getDerivedStateFromError(): AppErrorBoundaryState {
    return { hasError: true };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('InspectFlow 後台發生未預期錯誤', error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <main className="fatal-error" role="alert">
          <p className="section-kicker">無法顯示工作台</p>
          <h1>頁面發生未預期錯誤</h1>
          <p>請重新整理頁面；Prototype 不會將資料傳送至外部系統。</p>
          <button
            className="button button--primary"
            type="button"
            onClick={() => window.location.reload()}
          >
            重新整理
          </button>
        </main>
      );
    }

    return this.props.children;
  }
}
