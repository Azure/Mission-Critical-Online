using System.Text.Json;

namespace AlwaysOn.Shared
{
    public static class Helpers
    {
        /// <summary>
        /// Serializes any object to a JSON string, using the global serialization options
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="dataObject"></param>
        /// <returns></returns>
        public static string JsonSerialize<T>(T dataObject)
        {
            return JsonSerializer.Serialize(dataObject, Globals.JsonSerializerOptions);
        }

        /// <summary>
        /// Deserializes a JSON string to T, using the global serialization options
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="dataString"></param>
        /// <returns></returns>
        public static T JsonDeserialize<T>(string dataString)
        {
            return JsonSerializer.Deserialize<T>(dataString, Globals.JsonSerializerOptions);
        }
    }
}
