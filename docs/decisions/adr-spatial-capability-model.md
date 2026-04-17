# ADR: Spatial Capability Model

## Context
Symphony requires spatial data processing capabilities to support EU Taxonomy K13 (climate change mitigation) and DNSH (Do No Significant Harm) regulatory requirements. The system needs to:
- Detect overlaps between project boundaries and protected areas
- Store and query spatial geometry data (polygons, points)
- Support spatial operations like intersection, containment, and distance calculations
- Integrate with the existing PostgreSQL database without breaking existing functionality

## Decision
We will use PostGIS extension for spatial data processing with the following specifications:
- **Extension**: PostGIS 3.x (latest stable version)
- **Geometry Types**: POLYGON for protected areas and project boundaries
- **SRID**: 4326 (WGS84 geographic coordinate system)
- **Spatial Index**: GiST index on geometry columns for query performance
- **Storage**: Native PostGIS geometry types (geometry, geography)

### Rationale
PostGIS is the industry-standard spatial extension for PostgreSQL with:
- Mature, well-documented spatial functions
- Strong community support and long-term maintenance
- Compliance with OGC (Open Geospatial Consortium) standards
- Integration with existing PostgreSQL infrastructure
- Support for complex spatial operations (ST_Intersects, ST_Contains, ST_DWithin, etc.)

### trade-off
**PostGIS vs Custom Geometry Handling:**
- **PostGIS Pros**: Standard spatial functions, spatial indexing, OGC compliance, mature ecosystem
- **PostGIS Cons**: Additional extension dependency, larger storage footprint, requires spatial expertise
- **Custom Geometry Pros**: No external dependencies, smaller footprint, full control over implementation
- **Custom Geometry Cons**: Reimplementing spatial operations is error-prone, no spatial indexing, limited functionality

**Decision**: PostGIS is chosen because the complexity of spatial operations (intersection, containment, distance calculations) and the need for spatial indexing outweigh the dependency overhead. The regulatory requirements (K13, DNSH) demand accurate spatial computations that custom implementations would likely get wrong.

## Consequences
### Positive
- Access to mature, tested spatial functions
- Spatial indexing for performant queries
- OGC compliance for interoperability
- Strong community support and documentation
- Ability to implement complex regulatory checks (K13 taxonomy alignment, DNSH spatial constraints)

### Negative
- Additional dependency on PostGIS extension (must be installed and maintained)
- Increased storage footprint for geometry columns
- Requires spatial expertise for query optimization
- Potential performance impact on non-spatial queries if spatial indexes are misconfigured

### Mitigation
- PostGIS installation will be documented in migration scripts
- Spatial indexes will be created only on geometry columns that require them
- Spatial queries will be isolated to specific regulatory check functions
- Performance testing will be included in verification scripts

## DNSH and K13 Requirements
### K13 Taxonomy Alignment
- Projects must be classified as K13-aligned if they contribute to climate change mitigation
- Spatial check: Project boundaries must not intersect protected areas with high conservation value unless K13-aligned

### DNSH (Do No Significant Harm)
- Projects must not cause significant harm to protected areas
- Spatial check: Project boundaries must not intersect protected areas unless specific exemptions apply
- Enforcement: `enforce_dns_harm()` trigger will reject projects that violate DNSH spatial constraints

## Protected Areas vs Project Boundaries
- **Protected Areas**: Defined in `protected_areas` table (source: external regulatory data)
- **Project Boundaries**: Defined in `project_boundaries` table (source: project submission data)
- **Boundary Definition**: Clear separation between the two tables to avoid confusion
- **Overlap Detection**: `ST_Intersects()` function used to detect spatial conflicts
