export function isLeaseLostError(error: unknown): boolean {
    const code = (error as { code?: string } | undefined)?.code;
    return code === 'P7002';
}
