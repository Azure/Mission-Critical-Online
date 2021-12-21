using System;
using System.Linq;

namespace GlobalOrchestrator.Model
{
    public class LoadProfile
    {
        public Geo[] geos { get; set; }
    }

    public class Geo
    {
        public string name { get; set; }
        public string timezone { get; set; }

        public bool enabled { get; set; }
        public Timeframe[] timeframes { get; set; }

        public TimeZoneInfo TimeZone
        {
            get
            {
                var timezoneUtcOffset = TimeSpan.Parse(timezone.Replace("UTC", "").Replace("+", ""));
                return TimeZoneInfo.GetSystemTimeZones().FirstOrDefault(tz => tz.BaseUtcOffset == timezoneUtcOffset);
            }
        }

        public class Timeframe
        {
            public string start { get; set; }
            public string end { get; set; }

            public TimeOnly Start => TimeOnly.Parse(start);
            public TimeOnly End => TimeOnly.Parse(end);

            public int numberOfUsers { get; set; }
            public int transitionTimeMinutes { get; set; }

            /// <summary>
            /// How many users to add/subtract per minute during the transitionTime
            /// based on a given baseline, which would be the previous load profile timeframe
            /// Depending on whether the previous timeframe load was higher or lower, RampUpPerMinute will be positive or negative
            /// </summary>
            /// <param name="baseline"></param>
            /// <returns></returns>
            public decimal RampUpPerMinute(int baseline = 0)
            {
                return (numberOfUsers - baseline) / (decimal)transitionTimeMinutes;
            }

            public override string ToString()
            {
                return $"start={start} end={end} numberOfUsers={numberOfUsers} transitionTimeMinutes={transitionTimeMinutes}";
            }
        }
    }
}