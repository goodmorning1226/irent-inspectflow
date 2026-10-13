import type { EvidenceImage as EvidenceImageData } from '../domain/caseEvidence';

interface EvidenceImageProps {
  evidence: EvidenceImageData;
  onOpen?: (evidence: EvidenceImageData) => void;
  compact?: boolean;
}

export function EvidenceImage({
  evidence,
  onOpen,
  compact = false,
}: EvidenceImageProps) {
  const content = evidence.src ? (
    <>
      <img alt={evidence.caption} src={evidence.src} />
      <span className="evidence-image__zoom">放大</span>
    </>
  ) : (
    <span className="evidence-image__missing">
      <strong>缺少基準影像</strong>
      <small>{evidence.caption}</small>
    </span>
  );

  return (
    <figure
      className={`evidence-image${compact ? ' evidence-image--compact' : ''}`}
    >
      {evidence.src ? (
        <button onClick={() => onOpen?.(evidence)} type="button">
          {content}
        </button>
      ) : (
        <div className="evidence-image__frame">{content}</div>
      )}
      <figcaption>
        <span>
          <strong>{evidence.label}</strong>
          <small>{evidence.caption}</small>
        </span>
        <em>{evidence.sourceLabel}</em>
      </figcaption>
    </figure>
  );
}
