using System;

namespace AlwaysOn.Shared
{
    public static class Constants
    {
        // Action names for the data sent over the message bus
        public const string AddCatalogItemActionName = "AddCatalogItem";
        public const string AddCommentActionName = "AddComment";
        public const string AddRatingActionName = "AddRating";
        public const string DeleteObjectActionName = "DeleteObject";
    }
}
