namespace AlwaysOn.Shared.Models.DataTransfer
{
    public class DeleteObjectRequest
    {
        public string ObjectType { get; set; }
        public string ObjectId { get; set; }
        public string PartitionId { get; set; }
    }
}
