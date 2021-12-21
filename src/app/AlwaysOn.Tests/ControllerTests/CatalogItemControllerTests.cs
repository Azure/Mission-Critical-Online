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
/*
        [Test]
        public async Task ListGameResults_Returns_GameResults()
        {
            // Arrange
            var mockDatabase = new Mock<IDatabaseService>();
            mockDatabase.Setup(db => db.GetLatestGameResultsAsync(100))
                        .ReturnsAsync(GetTestGameResults());

            var controller = new CatalogItemController(mockLogger, mockDatabase.Object);

            // Act
            var result = await controller.ListGameResultsAsync();

            // Assert
            Assert.IsInstanceOf<ActionResult<IEnumerable<GameResult>>>(result); // expecting list of gameresults
            Assert.IsInstanceOf<OkObjectResult>(result.Result); // expecting HTTP 200 result
        }

        [Test]
        public async Task ListGameResults_DatabaseUnavailable_Returns_InternalServerError()
        {
            // Arrange
            var mockDatabase = new Mock<IDatabaseService>();
            mockDatabase.Setup(db => db.GetLatestGameResultsAsync(100))
                        .Throws(new AlwaysOnDependencyException(HttpStatusCode.ServiceUnavailable));

            var controller = new GameController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.ListGameResultsAsync();

            // Assert
            Assert.IsInstanceOf<ObjectResult>(result.Result);
            Assert.AreEqual((int)HttpStatusCode.InternalServerError, ((ObjectResult)result.Result).StatusCode);
        }

        [Test]
        public async Task ListGameResults_TooManyRequests_Returns_ServiceUnavailable()
        {
            // Arrange
            var mockDatabase = new Mock<IDatabaseService>();
            mockDatabase.Setup(db => db.GetLatestGameResultsAsync(100))
                        .Throws(new AlwaysOnDependencyException(HttpStatusCode.TooManyRequests));

            var controller = new GameController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.ListGameResultsAsync();

            // Assert
            Assert.IsInstanceOf<ObjectResult>(result.Result);
            Assert.AreEqual((int)HttpStatusCode.ServiceUnavailable, ((ObjectResult)result.Result).StatusCode);
        }

        [Test]
        public async Task DeleteGameResult_NotExisting_Returns_Accepted()
        {
            // Arrange
            Guid gameResultId = Guid.Empty;
            var mockDatabase = new Mock<IDatabaseService>();

            mockDatabase.Setup(db => db.GetCatalogItemByIdAsync(gameResultId))
                        .ReturnsAsync((GameResult)null);

            mockDatabase.Setup(db => db.DeleteObjectAsync<GameResult>(gameResultId.ToString()));

            var controller = new GameController(mockLogger, mockDatabase.Object, null, null);

            // Act
            var result = await controller.DeleteGameResultAsync(gameResultId);

            // Assert
            Assert.IsInstanceOf<ObjectResult>(result);
        }

        private List<GameResult> GetTestGameResults()
        {
            var g1 = new List<PlayerGesture>();
            g1.Add(new PlayerGesture()
            {
                Gesture = Gesture.Rock,
                PlayerId = Guid.NewGuid()
            });
            g1.Add(new PlayerGesture()
            {
                Gesture = Gesture.Paper,
                PlayerId = Guid.Parse("8b1f7d55-6ec4-45c7-aa4a-98d08e67c2ff")
            });

            var g2 = new List<PlayerGesture>();
            g2.Add(new PlayerGesture()
            {
                Gesture = Gesture.Lizard,
                PlayerId = Guid.NewGuid()
            });
            g2.Add(new PlayerGesture()
            {
                Gesture = Gesture.Lizard,
                PlayerId = Guid.NewGuid()
            });

            return new List<GameResult>()
            {
                new GameResult()
                {
                    GameDate = DateTime.UtcNow,
                    Id = Guid.NewGuid(),
                    PlayerGestures= g1,
                    WinningPlayerId = Guid.Parse("8b1f7d55-6ec4-45c7-aa4a-98d08e67c2ff")
                },
                new GameResult() {
                    GameDate = DateTime.UtcNow.AddDays(-1),
                    Id = Guid.NewGuid(),
                    PlayerGestures= g2,
                    WinningPlayerId = Guid.Empty

                }
            };

        }
*/
    }
}