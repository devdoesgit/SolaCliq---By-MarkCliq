import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { Amount, AmountSummary, Button, Notice, StageTracker, StatusPill, TextField } from '.';

describe('Button', () => {
  it('calls onClick and is a real button', async () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Save expense</Button>);
    const button = screen.getByRole('button', { name: 'Save expense' });
    expect(button).toHaveAttribute('type', 'button');
    await userEvent.click(button);
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('does nothing when disabled', async () => {
    const onClick = vi.fn();
    render(
      <Button disabled onClick={onClick}>
        Submit
      </Button>,
    );
    await userEvent.click(screen.getByRole('button', { name: 'Submit' }));
    expect(onClick).not.toHaveBeenCalled();
  });
});

describe('TextField', () => {
  it('labels the input and describes it with help', () => {
    render(<TextField label="Customer name" help="As on the electricity bill" />);
    const input = screen.getByLabelText('Customer name');
    expect(input).toHaveAccessibleDescription('As on the electricity bill');
    expect(input).not.toHaveAttribute('aria-invalid');
  });

  it('marks errors invalid and announces them', () => {
    render(<TextField label="Meter number" help="On the meter" error="Enter the meter number." />);
    const input = screen.getByLabelText('Meter number');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveAccessibleDescription('Enter the meter number.');
    expect(screen.getByRole('alert')).toHaveTextContent('Enter the meter number.');
    expect(screen.queryByText('On the meter')).not.toBeInTheDocument();
  });
});

describe('StatusPill', () => {
  it('shows its word', () => {
    render(<StatusPill label="Approved" tone="success" />);
    expect(screen.getByText('Approved')).toHaveClass('sc-tone-success');
  });
});

describe('StageTracker', () => {
  it('marks the current stage and reads each state', () => {
    render(
      <StageTracker
        stages={[
          { name: 'Lead', state: 'done', date: new Date(2026, 9, 2) },
          { name: 'Quote', state: 'current' },
          { name: 'Install', state: 'upcoming' },
        ]}
      />,
    );
    const items = screen.getAllByRole('listitem');
    expect(items[1]).toHaveAttribute('aria-current', 'step');
    expect(items[0]).toHaveTextContent('Lead, done');
    expect(items[0]).toHaveTextContent('2 Oct 2026');
    expect(items[2]).toHaveTextContent('Install, not started');
  });
});

describe('Amount', () => {
  it('formats paise and shows credits negative', () => {
    render(
      <>
        <Amount paise={18500000} />
        <Amount paise={500000} tone="credit" />
      </>,
    );
    expect(screen.getByText('₹1,85,000.00')).toBeInTheDocument();
    expect(screen.getByText('−₹5,000.00')).toBeInTheDocument();
  });

  it('summary lists lines and the total', () => {
    render(
      <AmountSummary
        lines={[{ label: 'Subsidy', paise: 7800000, tone: 'credit' }]}
        total={{ label: 'Total', paise: 4200000 }}
      />,
    );
    expect(screen.getByText('Subsidy')).toBeInTheDocument();
    expect(screen.getByText('−₹78,000.00')).toBeInTheDocument();
    expect(screen.getByText('₹42,000.00')).toBeInTheDocument();
  });
});

describe('Notice', () => {
  it('announces when asked', () => {
    render(<Notice tone="danger" title="Upload failed" announce />);
    expect(screen.getByRole('alert')).toHaveTextContent('Upload failed');
  });
});
