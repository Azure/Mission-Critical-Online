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

        public DateTime CreationDate { get; set; }

        public bool Deleted { get; set; }
    }
}
