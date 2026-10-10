import { NavLink, Outlet, useLocation } from 'react-router-dom';

import { AppIcon, type IconName } from '../components/AppIcon';
import { PrototypeBadge } from '../components/PrototypeBadge';
import { ScenarioControl } from '../components/ScenarioControl';

interface NavigationItem {
  label: string;
  to: string;
  icon: IconName;
}

const navigationItems: NavigationItem[] = [
  { label: '車況比對', to: '/cases', icon: 'cases' },
  { label: '任務分配', to: '/tasks', icon: 'tasks' },
  { label: '索賠審查', to: '/claims', icon: 'claims' },
];

function pageTitle(pathname: string) {
  return (
    navigationItems.find((item) => pathname.startsWith(item.to))?.label ??
    '營運工作台'
  );
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

        <ScenarioControl />

        <div className="sidebar-note">
          <AppIcon name="shield" />
          <p>AI 整理車況證據；派工與索賠仍由營運人員確認。</p>
        </div>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div>
            <span className="breadcrumb">InspectFlow／營運工作台</span>
            <h1>{pageTitle(location.pathname)}</h1>
          </div>
          <div className="topbar-actions">
            <span className="workspace-mode">單一營運視角</span>
            <PrototypeBadge />
          </div>
        </header>

        <main className="workspace-content">
          <Outlet />
        </main>
      </section>
    </div>
  );
}
