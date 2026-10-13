import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import { AppShell } from './AppShell';
import { CaseDetailPage } from '../pages/CaseDetailPage';
import { CasesPage } from '../pages/CasesPage';
import { FleetPage } from '../pages/FleetPage';
import { FleetDetailPage } from '../pages/FleetDetailPage';
import { NotFoundPage } from '../pages/NotFoundPage';
import { TaskDetailPage } from '../pages/TaskDetailPage';
import { TasksPage } from '../pages/TasksPage';

export function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<Navigate replace to="/cases" />} />
          <Route path="dashboard" element={<Navigate replace to="/cases" />} />
          <Route path="cases" element={<CasesPage />} />
          <Route path="cases/:caseId" element={<CaseDetailPage />} />
          <Route path="processing" element={<TasksPage />} />
          <Route path="processing/:taskId" element={<TaskDetailPage />} />
          <Route
            path="tasks/*"
            element={<Navigate replace to="/processing" />}
          />
          <Route
            path="claims/*"
            element={<Navigate replace to="/processing" />}
          />
          <Route path="fleet" element={<FleetPage />} />
          <Route path="fleet/:vehicleId" element={<FleetDetailPage />} />
          <Route path="audit" element={<Navigate replace to="/cases" />} />
          <Route path="*" element={<NotFoundPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
