using System;

namespace KhandobaSecureDocs.Models
{
    public class DocumentVersion
    {
        public Guid Id { get; set; }
        public Guid DocumentId { get; set; }
        public int VersionNumber { get; set; }
        public DateTime CreatedAt { get; set; }
        public long FileSize { get; set; }
        public string? Changes { get; set; }
    }
}
