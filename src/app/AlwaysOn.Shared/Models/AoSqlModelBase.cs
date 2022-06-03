using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Models
{
    public class AoSqlModelBase
    {
        public int Id { get; set; }

        /// <summary>
        /// This property determines which item in the database is the latest.
        /// </summary>
        public DateTime CreationDate { get; set; }

        /// <summary>
        /// When an item shouldn't be returned from the database and should be scheduled for deletion,
        /// this property should be set to true.
        /// </summary>
        public bool Deleted { get; set; }
    }
}
