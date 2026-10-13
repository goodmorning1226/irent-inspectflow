export type IconName =
  | 'dashboard'
  | 'cases'
  | 'tasks'
  | 'claims'
  | 'fleet'
  | 'audit'
  | 'shield'
  | 'filter'
  | 'arrow'
  | 'check';

interface AppIconProps {
  name: IconName;
  size?: number;
}

const paths: Record<IconName, string> = {
  dashboard: 'M4 4h6v6H4V4Zm10 0h6v6h-6V4ZM4 14h6v6H4v-6Zm10 0h6v6h-6v-6Z',
  cases: 'M5 4h14v16H5V4Zm3 4h8M8 12h8M8 16h5',
  tasks: 'M7 4h10v3H7V4ZM5 7h14v13H5V7Zm3 4h8M8 15h5',
  claims:
    'M12 3 4 7v5c0 4.8 3.4 7.8 8 9 4.6-1.2 8-4.2 8-9V7l-8-4Zm0 5v5m0 3h.01',
  fleet:
    'M5 16h14l-1.4-6.1A2 2 0 0 0 15.65 8h-7.3A2 2 0 0 0 6.4 9.9L5 16Zm2 0v2m10-2v2M8 13h.01M16 13h.01',
  audit: 'M5 4h14v16H5V4Zm4 4h6M9 12h6M9 16h4',
  shield:
    'M12 3 5 6v6c0 4.4 2.8 7.2 7 9 4.2-1.8 7-4.6 7-9V6l-7-3Zm-3 9 2 2 4-5',
  filter: 'M4 6h16M7 12h10m-7 6h4',
  arrow: 'M5 12h14m-5-5 5 5-5 5',
  check: 'm5 12 4 4L19 6',
};

export function AppIcon({ name, size = 20 }: AppIconProps) {
  return (
    <svg
      aria-hidden="true"
      className="app-icon"
      fill="none"
      height={size}
      viewBox="0 0 24 24"
      width={size}
    >
      <path
        d={paths[name]}
        fill={name === 'dashboard' ? 'currentColor' : 'none'}
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.8"
      />
    </svg>
  );
}
