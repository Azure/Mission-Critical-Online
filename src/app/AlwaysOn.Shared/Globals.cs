using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AlwaysOn.Shared
{
    public static class Globals
    {
        /// <summary>
        /// Using the same Json Serialization settings everywhere:
        /// - PropertyNamingPolicy: CamelCase
        /// - DefaultIgnoreCondition: WhenWritingNull
        /// </summary>
        public static readonly JsonSerializerOptions JsonSerializerOptions = new JsonSerializerOptions() 
        { 
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase, 
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        };
    }
}
