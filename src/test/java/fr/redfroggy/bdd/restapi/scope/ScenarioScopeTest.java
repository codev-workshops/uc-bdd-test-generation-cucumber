package fr.redfroggy.bdd.restapi.scope;

import org.junit.Assert;
import org.junit.Test;

public class ScenarioScopeTest {

    ScenarioScope scenarioScope = new ScenarioScope();

    @Test
    public void shouldBeInitialized() {
        Assert.assertNotNull(scenarioScope.getHeaders());
        Assert.assertNotNull(scenarioScope.getJsonPaths());
    }

    @Test
    public void shouldClearHeadersAndJsonPaths() {
        scenarioScope.getHeaders().put("token", "value");
        scenarioScope.getJsonPaths().put("id", "1");

        scenarioScope.clear();

        Assert.assertTrue(scenarioScope.getHeaders().isEmpty());
        Assert.assertTrue(scenarioScope.getJsonPaths().isEmpty());
    }
}
