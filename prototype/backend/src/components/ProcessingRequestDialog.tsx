import { useEffect, useState } from 'react';

import type { TaskType } from '../domain/types';

export type ProcessingMethod = Extract<
  TaskType,
  'cleaning' | 'repair' | 'suspension'
>;

const options: Array<{
  value: ProcessingMethod;
  label: string;
  description: string;
}> = [
  {
    value: 'cleaning',
    label: '清潔',
    description: '將車況證據與位置送往既有清潔處理系統。',
  },
  {
    value: 'repair',
    label: '維修',
    description: '將損傷證據送往既有維修與車輛調度系統。',
  },
  {
    value: 'suspension',
    label: '單純停用',
    description: '暫停車輛供租，不建立清潔或維修工作。',
  },
];

interface ProcessingRequestDialogProps {
  open: boolean;
  includeClaim?: boolean;
  plateNumber: string;
  onClose: () => void;
  onConfirm: (method: ProcessingMethod) => void;
}

export function ProcessingRequestDialog({
  open,
  includeClaim = false,
  plateNumber,
  onClose,
  onConfirm,
}: ProcessingRequestDialogProps) {
  const [method, setMethod] = useState<ProcessingMethod>('cleaning');

  useEffect(() => {
    if (open) setMethod('cleaning');
  }, [open]);

  if (!open) return null;

  return (
    <div className="request-dialog-backdrop" role="presentation">
      <section
        aria-labelledby="processing-dialog-title"
        aria-modal="true"
        className="request-dialog"
        role="dialog"
      >
        <header>
          <div>
            <h2 id="processing-dialog-title">選擇處理方式</h2>
            <p>
              {plateNumber}
              {includeClaim ? '・同步送出索賠請求' : ''}
            </p>
          </div>
          <button aria-label="關閉" onClick={onClose} type="button">
            ×
          </button>
        </header>

        <div className="request-methods" role="radiogroup">
          {options.map((option) => (
            <label
              className={method === option.value ? 'is-selected' : ''}
              key={option.value}
            >
              <input
                checked={method === option.value}
                name="processing-method"
                onChange={() => setMethod(option.value)}
                type="radio"
              />
              <span>
                <strong>{option.label}</strong>
                <small>{option.description}</small>
              </span>
            </label>
          ))}
        </div>

        <footer>
          <button className="button" onClick={onClose} type="button">
            取消
          </button>
          <button
            className="button button--primary"
            onClick={() => onConfirm(method)}
            type="button"
          >
            確認送出
          </button>
        </footer>
      </section>
    </div>
  );
}
