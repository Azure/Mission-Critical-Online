using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Models.Mapping
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // Ignore ID when mapping to the Write entities, because it's an IDENTITY column generated automatically (and we are always appending, there are no UPDATEs.
            CreateMap<CatalogItem, CatalogItemWrite>()
                .ForMember(dest => dest.Id, opt => opt.Condition(src => (src.Id == 0)));
            
            CreateMap<ItemComment, ItemCommentWrite>()
                .ForMember(dest => dest.Id, opt => opt.Condition(src => (src.Id == 0)));

            CreateMap<ItemRating, ItemRatingWrite>()
                .ForMember(dest => dest.Id, opt => opt.Condition(src => (src.Id == 0)));

            // Alternatively, this can be used to disable Id mapping globally.
            //ShouldMapProperty = p => p.Name != "Id";
        }
    }
}
