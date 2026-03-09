using Microsoft.AspNetCore.Http;
using System.Net;
using Xunit;

public class RequestSecurityGuardsTests
{
    [Fact]
    public void BuildRateLimitPartitionKey_UsesTenantAndRemoteClientIp()
    {
        var ctx = new DefaultHttpContext();
        ctx.Request.Headers["x-tenant-id"] = "tenant-abc";
        ctx.Connection.RemoteIpAddress = IPAddress.Parse("198.51.100.10");

        var key = RequestSecurityGuards.BuildRateLimitPartitionKey(ctx);

        Assert.Equal("tenant-abc|198.51.100.10", key);
    }

    [Fact]
    public async Task IsBodyTooLargeAsync_RejectsChunkedBodyOverLimit()
    {
        var ctx = new DefaultHttpContext();
        var payload = new byte[2048];
        ctx.Request.Method = HttpMethods.Post;
        ctx.Request.Body = new MemoryStream(payload);
        ctx.Request.ContentLength = null;

        var tooLarge = await RequestSecurityGuards.IsBodyTooLargeAsync(ctx.Request, 1024, CancellationToken.None);

        Assert.True(tooLarge);
    }

    [Fact]
    public async Task IsBodyTooLargeAsync_AllowsChunkedBodyWithinLimit()
    {
        var ctx = new DefaultHttpContext();
        var payload = new byte[512];
        ctx.Request.Method = HttpMethods.Post;
        ctx.Request.Body = new MemoryStream(payload);
        ctx.Request.ContentLength = null;

        var tooLarge = await RequestSecurityGuards.IsBodyTooLargeAsync(ctx.Request, 1024, CancellationToken.None);

        Assert.False(tooLarge);
    }
}
