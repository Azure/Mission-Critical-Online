using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Exceptions
{
    public class AlwaysOnDependencyException : Exception
    {
        public AlwaysOnDependencyException(HttpStatusCode statusCode, string message = null, Exception innerException = null) : base(message != null ? message : innerException?.Message, innerException)
        {
            StatusCode = statusCode;
        }

        public AlwaysOnDependencyException() { }

        public HttpStatusCode StatusCode { get; set; }
        public string DependencyName { get; set; }
    }
}
