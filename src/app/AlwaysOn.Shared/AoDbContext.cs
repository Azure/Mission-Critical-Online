#nullable disable // from sample: https://github.com/Azure-Samples/dotnetcore-sqldb-tutorial/blob/master/Data/MyDatabaseContext.cs
using AlwaysOn.Shared.Models;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace AlwaysOn.Shared
{
    public class AoDbContext : DbContext
    {
        public AoDbContext(DbContextOptions options) : base(options) { }

        public DbSet<CatalogItemRead> CatalogItemsRead { get; set; }
        public DbSet<CatalogItemWrite> CatalogItemsWrite { get; set; }

        public DbSet<ItemCommentRead> ItemCommentsRead { get; set; }
        public DbSet<ItemCommentWrite> ItemCommentsWrite { get; set; }

        public DbSet<ItemRatingRead> ItemRatingsRead { get; set; }
        public DbSet<ItemRatingWrite> ItemRatingsWrite { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
        //    modelBuilder.Entity<ItemCommentRead>(e =>
        //    {
        //        //e.HasNoKey();
        //        e.ToView("AllActiveComments", "ao");
        //    });

        //    modelBuilder.Entity<ItemCommentWrite>(e =>
        //    {
        //        e.ToTable("Comments", "ao");
        //    });
        }
    }
}
