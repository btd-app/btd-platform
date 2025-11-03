/**
 * BTD Platform Setup - Folder and View Creation
 *
 * This file runs FIRST (alphabetically) to create folder structure
 * before other job definitions try to use it.
 */

// Create folder structure
folder('btd-platform') {
    displayName('BTD Platform')
    description('BTD platform deployment pipelines')
}

// Create view for deployment jobs
listView('btd-platform/All Deployments') {
    description('All BTD deployment pipelines')
    jobs {
        regex('btd-platform/.*')
    }
    columns {
        status()
        weather()
        name()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}
