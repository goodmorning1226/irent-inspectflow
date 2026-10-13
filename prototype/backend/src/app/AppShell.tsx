import { NavLink, Outlet, useLocation } from 'react-router-dom';

import { AppIcon, type IconName } from '../components/AppIcon';

interface NavigationItem {
  label: string;
  to: string;
  icon: IconName;
}

const navigationItems: NavigationItem[] = [
  { label: '異常審核', to: '/cases', icon: 'cases' },
  { label: '處理中案件', to: '/processing', icon: 'tasks' },
  { label: '車輛管理', to: '/fleet', icon: 'fleet' },
];

function pageTitle(pathname: string) {
  if (pathname.startsWith('/cases/')) return '異常審核詳情';
  if (pathname.startsWith('/processing/')) return '處理案件詳情';
  if (pathname.startsWith('/cases')) return '異常案件審核';
  if (pathname.startsWith('/processing')) return '處理中案件';
  if (pathname.startsWith('/fleet')) return '車輛管理';
  return '營運工作台';
}

export function AppShell() {
  const location = useLocation();

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand-lockup">
          <span className="brand-mark" aria-hidden="true">
            i
          </span>
          <div>
            <strong>InspectFlow</strong>
            <span>AI 智能車況管家</span>
          </div>
        </div>

        <nav aria-label="主要功能" className="primary-nav">
          {navigationItems.map((item) => (
            <NavLink
              className={({ isActive }) =>
                `nav-link${isActive ? ' nav-link--active' : ''}`
              }
              key={item.to}
              to={item.to}
            >
              <AppIcon name={item.icon} />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div>
            <span className="breadcrumb">InspectFlow／營運工作台</span>
            <h1>{pageTitle(location.pathname)}</h1>
          </div>
        </header>

        <main className="workspace-content">
          <Outlet />
        </main>
      </section>
    </div>
  );
}
