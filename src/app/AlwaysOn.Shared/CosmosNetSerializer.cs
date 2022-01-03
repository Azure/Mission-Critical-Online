using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;

namespace AlwaysOn.Shared
{
    // Custom implementation of CosmosSerializer which works with System.Text.Json instead of Json.NET.
    // https://github.com/Azure/azure-cosmos-dotnet-v3/issues/202
    // This is temporary, until CosmosDB SDK v4 is available, which should remove the Json.NET dependency.
    public class CosmosNetSerializer : CosmosSerializer
    {
        private readonly JsonSerializerOptions _serializerOptions;

        public CosmosNetSerializer() => this._serializerOptions = null;

        public CosmosNetSerializer(JsonSerializerOptions serializerOptions) => this._serializerOptions = serializerOptions;

        public override T FromStream<T>(Stream stream)
        {
            using (stream)
            {
                if (typeof(Stream).IsAssignableFrom(typeof(T)))
                {
                    return (T)(object)stream;
                }

                return JsonSerializer.DeserializeAsync<T>(stream, this._serializerOptions).GetAwaiter().GetResult();

                //TODO: replace the above with sync variant using appropriate TextReader?
                //using (TextReader textReader = new TextReader(stream))
                //{
                //    return JsonSerializer.Deserialize<T>(textReader);
                //}
            }
        }

        public override Stream ToStream<T>(T input)
        {
            var outputStream = new MemoryStream();

            //TODO: replace with sync variant too?
            JsonSerializer.SerializeAsync<T>(outputStream, input, this._serializerOptions).GetAwaiter().GetResult();

            outputStream.Position = 0;
            return outputStream;
        }
    }
}
