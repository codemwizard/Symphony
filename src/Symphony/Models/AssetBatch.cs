namespace Symphony.Models
{
    public class AssetBatch
    {
        public DataAuthorityLevel DataAuthority { get; set; } = DataAuthorityLevel.Phase1IndicativeOnly;
        public bool AuditGrade { get; set; } = false;
    }

    public enum DataAuthorityLevel
    {
        Phase1IndicativeOnly,
        NonReproducible,
        Reproducible
    }
}
