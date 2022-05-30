using AlwaysOn.CatalogService.Controllers;
using AlwaysOn.Shared.Exceptions;
using AlwaysOn.Shared.Interfaces;
using AlwaysOn.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;

namespace AlwaysOn.Tests
{
    public class CatalogItemControllerTests
    {
        ILogger<CatalogItemController> mockLogger;

        [SetUp]
        public void Setup()
        {
            mockLogger = new Mock<ILogger<CatalogItemController>>().Object;
        }

        [Test]
        public async Task ListCatalogItems_Returns_CatalogItems()
        {
            // Arrange
            var mockDatabase = new Mock<IDatabaseService>();
            mockDatabase.Setup(db => db.ListCatalogItemsAsync(100))
                        .ReturnsAsync(GetTestCatalogItems());

            var controller = new CatalogItemController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.ListCatalogItemsAsync();

            // Assert
            Assert.IsInstanceOf<ActionResult<IEnumerable<CatalogItem>>>(result); // expecting list of CatalogItems
            Assert.IsInstanceOf<OkObjectResult>(result.Result); // expecting HTTP 200 result
        }

        [Test]
        public async Task ListCatalogItems_DatabaseUnavailable_Returns_InternalServerError()
        {
            // Arrange
            var mockDatabase = new Mock<IDatabaseService>();
            mockDatabase.Setup(db => db.ListCatalogItemsAsync(100))
                        .Throws(new AlwaysOnDependencyException(HttpStatusCode.ServiceUnavailable));

            var controller = new CatalogItemController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.ListCatalogItemsAsync();

            // Assert
            Assert.IsInstanceOf<ObjectResult>(result.Result);
            Assert.AreEqual((int)HttpStatusCode.InternalServerError, ((ObjectResult)result.Result).StatusCode);
        }

        [Test]
        public async Task ListCatalogItems_TooManyRequests_Returns_ServiceUnavailable()
        {
            // Arrange
            var mockDatabase = new Mock<IDatabaseService>();
            mockDatabase.Setup(db => db.ListCatalogItemsAsync(100))
                        .Throws(new AlwaysOnDependencyException(HttpStatusCode.TooManyRequests));

            var controller = new CatalogItemController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.ListCatalogItemsAsync();

            // Assert
            Assert.IsInstanceOf<ObjectResult>(result.Result);
            Assert.AreEqual((int)HttpStatusCode.ServiceUnavailable, ((ObjectResult)result.Result).StatusCode);
        }

        [Test]
        public async Task DeleteCatalogItem_NotExisting_Returns_Accepted()
        {
            // Arrange
            Guid itemId = Guid.Empty;
            var mockDatabase = new Mock<IDatabaseService>();

            mockDatabase.Setup(db => db.GetCatalogItemByIdAsync(itemId))
                        .ReturnsAsync((CatalogItem)null);

            mockDatabase.Setup(db => db.DeleteItemAsync<CatalogItem>(itemId.ToString(), itemId.ToString()));

            var controller = new CatalogItemController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.DeleteCatalogItemAsync(itemId);

            // Assert
            Assert.IsInstanceOf<ObjectResult>(result);
        }

        private List<CatalogItem> GetTestCatalogItems()
        {
            return new List<CatalogItem>()
            {
                new CatalogItem()
                {
                    LastUpdated = DateTime.UtcNow,
                    Id = 1,//Guid.NewGuid(),
                    Description= "First test item",
                    Name = "First Item",
                    Price = 11111.11m
                },
                new CatalogItem() {
                    LastUpdated = DateTime.UtcNow.AddDays(-1),
                    Id = 2,//Guid.NewGuid(),
                    Description= "Second test item",
                    Name = "Second Item",
                    Price = 99.99m

                }
            };

        }

    }
}