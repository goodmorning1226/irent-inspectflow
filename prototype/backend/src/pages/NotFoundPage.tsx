import { Link } from 'react-router-dom';

export function NotFoundPage() {
  return (
    <section className="empty-state" role="alert">
      <span className="empty-state__stage">404</span>
      <h2>找不到這個後台頁面</h2>
      <p>網址可能不完整，或此 Prototype 尚未建立對應路由。</p>
      <Link className="button button--primary" to="/dashboard">
        返回營運總覽
      </Link>
    </section>
  );
}
