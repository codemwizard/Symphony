using Microsoft.Extensions.Logging;
using Symphony.LedgerApi.Demo;

Environment.SetEnvironmentVariable("SYMPHONY_RUNTIME_PROFILE", "pilot-demo");

using var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.AddSimpleConsole(options =>
    {
        options.SingleLine = true;
        options.TimestampFormat = "HH:mm:ss ";
    });
});

var logger = loggerFactory.CreateLogger("LedgerApi.DemoHost");
var result = await DemoSelfTestEntryPoint.TryRunAsync(args, "pilot-demo", logger, CancellationToken.None);
if (result is null)
{
    logger.LogError("No supported self-test flag provided.");
    Environment.ExitCode = 64;
}
else
{
    Environment.ExitCode = result.Value;
}

