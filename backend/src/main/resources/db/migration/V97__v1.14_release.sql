ALTER TABLE test_plan
    DROP COLUMN principal;

-- 组织用户组配置到工作空间上
DROP PROCEDURE IF EXISTS test_cursor;
DELIMITER //
CREATE PROCEDURE test_cursor()
BEGIN
    DECLARE sourceId VARCHAR(64);
    DECLARE userId VARCHAR(64);
    DECLARE groupId VARCHAR(64);
    DECLARE done INT DEFAULT 0;
    DECLARE cursor1 CURSOR FOR (SELECT user_id, source_id, group_id
                                FROM user_group
                                WHERE group_id IN ('org_admin', 'org_member'));


    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor1;
    outer_loop:
    LOOP
        FETCH cursor1 INTO userId, sourceId, groupId;
        IF done
        THEN
            LEAVE outer_loop;
        END IF;
        INSERT INTO user_group (id, user_id, group_id, source_id, create_time, update_time)
        SELECT UUID(), userId, REPLACE(groupId, 'org', 'ws'), id, create_time, update_time
        FROM workspace
        WHERE organization_id = sourceId;
    END LOOP;
    CLOSE cursor1;
END
//
DELIMITER ;

CALL test_cursor();
DROP PROCEDURE IF EXISTS test_cursor;


CREATE TABLE IF NOT EXISTS relationship_edge
(
    source_id         varchar(50) NOT NULL COMMENT '源节点的ID',
    target_id         varchar(50) NOT NULL COMMENT '目标节点的ID',
    relationship_type varchar(20) NOT NULL COMMENT '关系的类型，前置后置或者依赖',
    resource_type     varchar(20) NOT NULL COMMENT '是表示什么资源',
    graph_id          varchar(50) NOT NULL COMMENT '所属关系图的ID',
    creator           varchar(50) NOT NULL COMMENT '创建人',
    create_time       bigint(13)  NOT NULL,
    PRIMARY KEY (source_id, target_id)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE utf8mb4_general_ci;

--
ALTER TABLE message_task
    ADD workspace_id VARCHAR(64) NULL;

-- 消息通知去掉组织


DROP PROCEDURE IF EXISTS test_cursor;
DELIMITER //
CREATE PROCEDURE test_cursor()
BEGIN
    DECLARE userId VARCHAR(64);
    DECLARE testId VARCHAR(64);
    DECLARE type VARCHAR(64);
    DECLARE event VARCHAR(64);
    DECLARE taskType VARCHAR(64);
    DECLARE webhook VARCHAR(255);
    DECLARE identification VARCHAR(64);
    DECLARE isSet VARCHAR(64);
    DECLARE organizationId VARCHAR(64);
    DECLARE createTime BIGINT;
    DECLARE template TEXT;

    DECLARE done INT DEFAULT 0;
    # 必须用 table_name.column_name
    DECLARE cursor1 CURSOR FOR SELECT message_task.type,
                                      message_task.event,
                                      message_task.user_id,
                                      message_task.task_type,
                                      message_task.webhook,
                                      message_task.identification,
                                      message_task.is_set,
                                      message_task.organization_id,
                                      message_task.test_id,
                                      message_task.create_time,
                                      message_task.template
                               FROM message_task;


    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor1;
    outer_loop:
    LOOP
        FETCH cursor1 INTO type, event, userId, taskType, webhook, identification, isSet,
            organizationId,
            testId, createTime, template;
        IF done
        THEN
            LEAVE outer_loop;
        END IF;
        INSERT INTO message_task(id, type, event, user_id, task_type, webhook, identification, is_set, workspace_id,
                                 test_id, create_time, template)
        SELECT UUID(),
               type,
               event,
               userId,
               taskType,
               webhook,
               identification,
               isSet,
               id,
               testId,
               createTime,
               template
        FROM workspace
        WHERE organization_id = organizationId;
        DELETE FROM message_task WHERE organization_id = organizationId;
    END LOOP;
    CLOSE cursor1;
END
//
DELIMITER ;

CALL test_cursor();
DROP PROCEDURE IF EXISTS test_cursor;
-- 去掉组织id
ALTER TABLE message_task
    DROP COLUMN organization_id;
