import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import { AppShell } from './AppShell';
import { CaseDetailPage } from '../pages/CaseDetailPage';
import { CasesPage } from '../pages/CasesPage';
import { ClaimDetailPage } from '../pages/ClaimDetailPage';
import { ClaimsPage } from '../pages/ClaimsPage';
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
          <Route path="tasks" element={<TasksPage />} />
          <Route path="tasks/:taskId" element={<TaskDetailPage />} />
          <Route path="claims" element={<ClaimsPage />} />
          <Route path="claims/:caseId" element={<ClaimDetailPage />} />
          <Route path="audit" element={<Navigate replace to="/cases" />} />
          <Route path="*" element={<NotFoundPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
