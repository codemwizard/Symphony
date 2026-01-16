/**
 * Phase-7B: Replay Verification Report
 * 
 * Produces a machine-readable comparison between reconstructed and actual state.
 * 
 * Summary:
 * - Matched entries
 * - Deviations (if any)
 * - Hashes of input and output datasets
 * 
 * Acceptance Criteria:
 * - Report is reproducible
 * - Supervisor can run it independently
 */

import { Pool } from 'pg';
import pino from 'pino';
import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { LedgerReplayEngine, ReconstructedBalance, ReplayConfig } from './ledger_replay.js';

const logger = pino({ name: 'ReplayVerificationReport' });

// ------------------ Types ------------------

export interface ActualBalance {
    readonly accountId: string;
    readonly currency: string;
    readonly balance: string;
}

export interface BalanceComparison {
    readonly accountId: string;
    readonly currency: string;
    readonly reconstructedBalance: string;
    readonly actualBalance: string;
    readonly difference: string;
    readonly match: boolean;
}

export interface VerificationReport {
    readonly reportId: string;
    readonly generatedAt: string;
    readonly config: ReplayConfig;

    // Input Hashes
    readonly inputHashes: {
        readonly attestations: string;
        readonly outbox: string;
        readonly ledger: string;
    };

    // Counts
    readonly attestationCount: number;
    readonly outboxCount: number;
    readonly ledgerEntryCount: number;
    readonly accountCount: number;

    // Comparison Results
    readonly totalMatched: number;
    readonly totalDeviations: number;
    readonly deviations: readonly BalanceComparison[];
    readonly allComparisons: readonly BalanceComparison[];

    // Summary
    readonly overallStatus: 'PASS' | 'FAIL' | 'WARNING';
    readonly summaryMessage: string;

    // Integrity
    readonly replayResultHash: string;
    readonly actualStateHash: string;
    readonly reportHash: string;
}

// ------------------ Core Logic ------------------

export class ReplayVerificationReportGenerator {
    private readonly pool: Pool;

    constructor(pool: Pool) {
        this.pool = pool;
    }

    /**
     * Generate a verification report comparing replayed vs actual state.
     */
    async generate(config: ReplayConfig = {}): Promise<VerificationReport> {
        const reportId = this.generateReportId();
        const generatedAt = new Date().toISOString();

        logger.info({ reportId, config }, 'Generating verification report');

        // Step 1: Run replay
        const replayEngine = new LedgerReplayEngine(this.pool);
        const replayResult = await replayEngine.replay(config);

        // Step 2: Fetch actual balances from database
        const actualBalances = await this.fetchActualBalances(config);

        // Step 3: Compare reconstructed vs actual
        const comparisons = this.compareBalances(replayResult.reconstructedBalances, actualBalances);

        // Step 4: Compute summary
        const deviations = comparisons.filter(c => !c.match);
        const totalMatched = comparisons.length - deviations.length;

        let overallStatus: 'PASS' | 'FAIL' | 'WARNING';
        let summaryMessage: string;

        if (deviations.length === 0) {
            overallStatus = 'PASS';
            summaryMessage = `All ${comparisons.length} account balances match exactly.`;
        } else if (deviations.length <= 3) {
            overallStatus = 'WARNING';
            summaryMessage = `${deviations.length} deviation(s) found out of ${comparisons.length} accounts. Review required.`;
        } else {
            overallStatus = 'FAIL';
            summaryMessage = `${deviations.length} deviation(s) found out of ${comparisons.length} accounts. Investigation required.`;
        }

        // Step 5: Compute hashes
        const actualStateHash = this.computeHash(actualBalances);

        const report: Omit<VerificationReport, 'reportHash'> = {
            reportId,
            generatedAt,
            config,
            inputHashes: replayResult.inputHashes,
            attestationCount: replayResult.attestationCount,
            outboxCount: replayResult.outboxCount,
            ledgerEntryCount: replayResult.ledgerEntryCount,
            accountCount: comparisons.length,
            totalMatched,
            totalDeviations: deviations.length,
            deviations,
            allComparisons: comparisons,
            overallStatus,
            summaryMessage,
            replayResultHash: replayResult.resultHash,
            actualStateHash,
        };

        const reportHash = this.computeHash(report);

        logger.info({
            reportId,
            overallStatus,
            totalMatched,
            totalDeviations: deviations.length,
            reportHash,
        }, 'Verification report generated');

        return { ...report, reportHash };
    }

    /**
     * Save report to filesystem as JSON.
     */
    async saveReport(report: VerificationReport, outputDir: string): Promise<string> {
        const filename = `verification_report_${report.reportId}.json`;
        const filepath = path.join(outputDir, filename);

        await fs.mkdir(outputDir, { recursive: true });
        await fs.writeFile(filepath, JSON.stringify(report, null, 2), 'utf-8');

        // Also write hash file
        const hashFilepath = `${filepath}.sha256`;
        await fs.writeFile(hashFilepath, report.reportHash, 'utf-8');

        logger.info({ filepath, hashFilepath }, 'Report saved to filesystem');

        return filepath;
    }

    // ------------------ Private Methods ------------------

    private generateReportId(): string {
        const timestamp = Date.now().toString(36);
        const random = crypto.randomBytes(4).toString('hex');
        return `rpt_${timestamp}_${random}`;
    }

    private async fetchActualBalances(config: ReplayConfig): Promise<ActualBalance[]> {
        const client = await this.pool.connect();
        try {
            let query = `
                SELECT 
                    account_id AS "accountId",
                    currency,
                    balance::TEXT AS balance
                FROM account_balances
                WHERE 1=1
            `;
            const params: unknown[] = [];

            if (config.accountFilter && config.accountFilter.length > 0) {
                params.push(config.accountFilter);
                query += ` AND account_id = ANY($${params.length})`;
            }

            query += ' ORDER BY account_id ASC';

            const result = await client.query(query, params);
            return result.rows as ActualBalance[];
        } finally {
            client.release();
        }
    }

    private compareBalances(
        reconstructed: readonly ReconstructedBalance[],
        actual: readonly ActualBalance[]
    ): BalanceComparison[] {
        const actualMap = new Map<string, ActualBalance>();
        for (const bal of actual) {
            actualMap.set(`${bal.accountId}:${bal.currency}`, bal);
        }

        const comparisons: BalanceComparison[] = [];

        for (const recon of reconstructed) {
            const key = `${recon.accountId}:${recon.currency}`;
            const actualBal = actualMap.get(key);

            if (actualBal) {
                const reconValue = parseFloat(recon.netBalance);
                const actualValue = parseFloat(actualBal.balance);
                const difference = (reconValue - actualValue).toFixed(2);
                const match = Math.abs(reconValue - actualValue) < 0.01; // 1 cent tolerance

                comparisons.push({
                    accountId: recon.accountId,
                    currency: recon.currency,
                    reconstructedBalance: recon.netBalance,
                    actualBalance: actualBal.balance,
                    difference,
                    match,
                });

                actualMap.delete(key);
            } else {
                // Reconstructed balance exists but no actual balance found
                comparisons.push({
                    accountId: recon.accountId,
                    currency: recon.currency,
                    reconstructedBalance: recon.netBalance,
                    actualBalance: 'N/A',
                    difference: recon.netBalance,
                    match: false,
                });
            }
        }

        // Any remaining actual balances not in reconstructed
        for (const [, actualBal] of actualMap) {
            comparisons.push({
                accountId: actualBal.accountId,
                currency: actualBal.currency,
                reconstructedBalance: 'N/A',
                actualBalance: actualBal.balance,
                difference: `-${actualBal.balance}`,
                match: false,
            });
        }

        return comparisons.sort((a, b) => a.accountId.localeCompare(b.accountId));
    }

    private computeHash(data: unknown): string {
        const json = JSON.stringify(data);
        return crypto.createHash('sha256').update(json).digest('hex');
    }
}

// ------------------ CLI Entry Point ------------------

export async function generateVerificationReport(
    pool: Pool,
    config: ReplayConfig,
    outputDir: string
): Promise<VerificationReport> {
    const generator = new ReplayVerificationReportGenerator(pool);
    const report = await generator.generate(config);
    await generator.saveReport(report, outputDir);
    return report;
}
