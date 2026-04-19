namespace Symphony.Models
{
    public class StateTransition
    {
        public DataAuthorityLevel DataAuthority { get; set; } = DataAuthorityLevel.NonReproducible;
        public bool AuditGrade { get; set; } = false;
    }
}
